#!/usr/bin/env bash
# Sign the coding-agent CLIs in once and commit that state as the image
# per-workspace create boots from. Two phases, because the logins need a TTY
# this script does not have:
#
#   docker-base-auth.sh start    boot an auth container and print the logins
#   docker-base-auth.sh finish   verify the logins, commit, update state
#
# Logs go to stderr; stdout carries only the merged state JSON (finish).
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
. "$script_dir/lib/common.sh"

require_cmd node
require_docker_daemon

phase="${1:-}"
base_name="$(env_value ORCA_BASE_NAME baseName 'orca-xihan-ui')"
source_image="$(env_value ORCA_BASE_IMAGE authSourceSnapshotId "${base_name}:base")"
auth_image="$(env_value ORCA_AUTH_IMAGE snapshotId "${base_name}:auth")"
auth_container="${base_name}-auth"

# Orca bakes its pairing identity and device registry into the runtime's
# user-data directory, so an image committed after `orca serve` ran would hand
# every workspace the same identity. Remove that directory, with the path
# checked, before committing.
scrub_runtime_state='
set -eu
path="${ORCA_USER_DATA_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/orca}"
case "$path" in
  /*) ;;
  *) echo "Refusing to scrub a non-absolute Orca data path: $path" >&2; exit 1 ;;
esac
[ -d "$path" ] || { echo "No Orca runtime state to scrub at $path" >&2; exit 0; }
resolved="$(cd "$path" && pwd -P)"
home_resolved="$(cd "$HOME" && pwd -P)"
case "$resolved" in
  / | "$home_resolved") echo "Refusing to scrub $resolved" >&2; exit 1 ;;
esac
case "$home_resolved" in
  "$resolved"/*) echo "Refusing to scrub $resolved: it contains the home directory" >&2; exit 1 ;;
esac
[ "$(basename "$resolved")" = "orca" ] || { echo "Refusing to scrub $resolved: not an Orca data directory" >&2; exit 1; }
rm -rf -- "$resolved"
echo "Scrubbed Orca runtime state at $resolved" >&2
'

agent_status='
if claude auth status >/dev/null 2>&1; then echo ORCA_CLAUDE_LOGGED_IN; else echo ORCA_CLAUDE_LOGGED_OUT; fi
if codex login status >/dev/null 2>&1; then echo ORCA_CODEX_LOGGED_IN; else echo ORCA_CODEX_LOGGED_OUT; fi
'

case "$phase" in
  start)
    image_exists "$source_image" || die "Base image $source_image is missing. Run docker-base-image.sh first."
    if container_exists "$auth_container"; then
      log "Reusing the existing auth container $auth_container"
      container_running "$auth_container" || docker start "$auth_container" >&2
    else
      docker run --detach --name "$auth_container" "$source_image" >&2
    fi
    log ""
    log "Run these two logins in your own terminal, then re-run this script with 'finish':"
    log "  docker exec -it $auth_container claude auth login"
    log "  docker exec -it $auth_container codex login --device-auth"
    log ""
    log "Both print a URL and a code to open on this machine. Nothing is written to the repo."
    ;;
  finish)
    container_exists "$auth_container" || die "No auth container $auth_container. Run 'start' first."
    container_running "$auth_container" || docker start "$auth_container" >&2

    verdict="$(docker exec "$auth_container" bash -lc "$agent_status")"
    printf '%s\n' "$verdict" >&2
    case "$verdict" in
      *ORCA_CLAUDE_LOGGED_IN*) ;;
      *) die "claude is not signed in; not committing. Run: docker exec -it $auth_container claude auth login" ;;
    esac
    case "$verdict" in
      *ORCA_CODEX_LOGGED_IN*) ;;
      *) die "codex is not signed in; not committing. Run: docker exec -it $auth_container codex login --device-auth" ;;
    esac

    docker exec "$auth_container" bash -lc "$scrub_runtime_state" >&2

    log "Committing $auth_container as $auth_image"
    docker commit \
      --change 'ENTRYPOINT ["/usr/bin/tini", "--"]' \
      --change 'CMD ["sleep", "infinity"]' \
      --message "Orca agent auth layer" \
      "$auth_container" "$auth_image" >&2
    image_exists "$auth_image" || die "Commit reported success but $auth_image does not exist"

    docker rm --force "$auth_container" >&2

    state_merge "$(node -e 'const [a,s]=process.argv.slice(1);
process.stdout.write(JSON.stringify({snapshotId:a, authSourceSnapshotId:s}))' "$auth_image" "$source_image")"
    ;;
  *)
    die "Usage: docker-base-auth.sh start|finish"
    ;;
esac
