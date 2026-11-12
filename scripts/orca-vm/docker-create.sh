#!/usr/bin/env bash
# Per-workspace create: boot a container from the authenticated image, bring the
# checkout up to date, start the headless Orca runtime, and print the recipe
# result. stdout carries exactly one JSON object.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
. "$script_dir/lib/common.sh"

require_cmd node
require_docker_daemon

base_name="$(env_value ORCA_BASE_NAME baseName 'orca-xihan-ui')"
image="$(env_value ORCA_AUTH_IMAGE snapshotId "${base_name}:auth")"
port="$(env_value ORCA_PORT port '6768')"
repo_ref="$(env_value ORCA_REPO_REF repoRef 'dev')"
project_root="$(env_value ORCA_PROJECT_ROOT projectRoot '/home/orca/XiHan.UI')"

image_exists "$image" || die "Image $image is missing. Run docker-base-image.sh, then docker-base-auth.sh start/finish."

recipe_id="$(sanitize_docker_name "${ORCA_RECIPE_ID:-docker-sandbox}" 48)"
instance_id="$(sanitize_docker_name "${ORCA_VM_INSTANCE_ID:-$(date +%s)}" 60)"
name="orca-${recipe_id}-${instance_id}"

created_here=false
cleanup_on_error() {
  local status=$?
  trap - EXIT
  if [ "$status" -ne 0 ] && [ "$created_here" = true ]; then
    docker rm --force "$name" >/dev/null 2>&1 || true
  fi
  exit "$status"
}
trap cleanup_on_error EXIT

if container_exists "$name"; then
  # A create that timed out or was retried must not leak a second container.
  log "Reusing the existing container $name"
  container_running "$name" || docker start "$name" >&2
else
  run_args=(
    --detach
    --name "$name"
    --publish "127.0.0.1::${port}"
    --label "orca.provider=docker"
    --label "orca.recipe-id=${recipe_id}"
    --label "orca.instance-id=${instance_id}"
  )
  token="$(gh_token)"
  if [ -n "$token" ]; then
    run_args+=(--env "GH_TOKEN=$token")
  else
    log "No GitHub token found on the host; pushes from inside the environment will not be authorized."
  fi
  docker run "${run_args[@]}" "$image" >&2
  created_here=true
fi

host_port="$(published_port "$name" "$port")" || die "Docker published no host port for ${port}/tcp on $name"
pairing_address="ws://127.0.0.1:${host_port}"

log "Syncing the checkout to $repo_ref"
docker exec \
  --env "ORCA_PROJECT_ROOT=$project_root" \
  --env "ORCA_REPO_REF=$repo_ref" \
  "$name" orca-sync-repo >&2

log "Starting the Orca runtime, advertising $pairing_address"
recipe_json="$(docker exec \
  --env "ORCA_PORT=$port" \
  --env "ORCA_PROJECT_ROOT=$project_root" \
  --env "ORCA_PAIRING_ADDRESS=$pairing_address" \
  "$name" orca-serve-recipe)"

node -e '
const [raw, resourceId, image, hostPort] = process.argv.slice(1);
const served = JSON.parse(raw);
process.stdout.write(JSON.stringify({
  ...served,
  schemaVersion: 1,
  userData: { ...served.userData, provider: "docker", resourceId, image, hostPort: Number(hostPort) }
}));
' "$recipe_json" "$name" "$image" "$host_port"
printf '\n'

trap - EXIT
