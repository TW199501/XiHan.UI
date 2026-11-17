# shellcheck shell=bash
# Shared helpers for the XiHan.UI per-workspace Docker environment scripts.
# Every caller reserves stdout for its final JSON object; helpers log to stderr.

# Git Bash rewrites arguments that look like POSIX paths before handing them to
# docker.exe, which would turn /home/orca/... into a Windows path.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

ORCA_VM_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ORCA_VM_DIR="$(cd -- "$ORCA_VM_LIB_DIR/.." && pwd -P)"
ORCA_VM_REPO_DIR="$(cd -- "$ORCA_VM_DIR/../.." && pwd -P)"
ORCA_VM_STATE_FILE="${ORCA_VM_STATE_FILE:-$ORCA_VM_DIR/docker-state.json}"

log() { printf '%s\n' "$*" >&2; }
die() { log "$*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found on PATH: $1"
}

require_docker_daemon() {
  require_cmd docker
  docker version --format '{{.Server.Version}}' >/dev/null 2>&1 \
    || die "The Docker daemon is not reachable. Start Docker Desktop and retry."
}

# json_value <key> [fallback] — read a key from the state file.
json_value() {
  local key="$1" fallback="${2-}"
  [ -f "$ORCA_VM_STATE_FILE" ] || { printf '%s' "$fallback"; return 0; }
  node -e '
const fs = require("node:fs");
const [file, key, fallback] = process.argv.slice(1);
let value;
try { value = JSON.parse(fs.readFileSync(file, "utf8"))[key]; } catch { value = undefined; }
process.stdout.write(value === undefined || value === null || value === "" ? fallback : String(value));
' "$ORCA_VM_STATE_FILE" "$key" "$fallback"
}

# env_value <ENV_NAME> <state-key> [fallback] — env var, then state, then fallback.
env_value() {
  local name="$1" key="$2" fallback="${3-}" value
  value="$(printf '%s' "${!name-}")"
  if [ -n "$value" ]; then printf '%s' "$value"; return 0; fi
  json_value "$key" "$fallback"
}

# state_merge <json-object> — merge keys into the state file, preserving the rest.
state_merge() {
  node -e '
const fs = require("node:fs");
const [file, patchText] = process.argv.slice(1);
let current = {};
try { current = JSON.parse(fs.readFileSync(file, "utf8")); } catch { current = {}; }
const merged = { ...current, ...JSON.parse(patchText) };
fs.writeFileSync(file, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
process.stdout.write(JSON.stringify(merged, null, 2));
' "$ORCA_VM_STATE_FILE" "$1"
}

# sanitize_docker_name <value> <max-length> — keep only characters Docker accepts.
sanitize_docker_name() {
  local raw="$1" max="$2" cleaned
  cleaned="$(printf '%s' "$raw" | tr -c 'a-zA-Z0-9_.-' '-')"
  printf '%s' "${cleaned:0:max}"
}

container_exists() { docker container inspect "$1" >/dev/null 2>&1; }
container_running() { [ "$(docker container inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]; }
image_exists() { docker image inspect "$1" >/dev/null 2>&1; }

# published_port <container> <container-port> — host port Docker mapped.
published_port() {
  local mapping
  mapping="$(docker port "$1" "$2/tcp" 2>/dev/null | head -1)"
  [ -n "$mapping" ] || return 1
  printf '%s' "${mapping##*:}"
}

# gh_token — host-side token for the dry-run push check inside the environment.
gh_token() {
  if [ -n "${GH_TOKEN:-}" ]; then printf '%s' "$GH_TOKEN"; return 0; fi
  if [ -n "${GITHUB_TOKEN:-}" ]; then printf '%s' "$GITHUB_TOKEN"; return 0; fi
  command -v gh >/dev/null 2>&1 && gh auth token 2>/dev/null || true
}
