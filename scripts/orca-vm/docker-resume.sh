#!/usr/bin/env bash
# Resume: start the container, re-read its published port, restart the runtime,
# and print fresh recipe JSON — Docker republishes a different host port after a
# stop, so the pairing address changes. stdout carries exactly one JSON object.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/lifecycle.sh
. "$script_dir/lib/lifecycle.sh"

require_cmd node
require_docker_daemon

base_name="$(env_value ORCA_BASE_NAME baseName 'orca-xihan-ui')"
port="$(env_value ORCA_PORT port '6768')"
project_root="$(env_value ORCA_PROJECT_ROOT projectRoot '/home/orca/XiHan.UI')"
repo_ref="$(env_value ORCA_REPO_REF repoRef 'dev')"

payload="$(read_lifecycle_payload)"
resource_id="$(lifecycle_resource_id "$payload")"
[ -n "$resource_id" ] || die "No resource id in the lifecycle payload"
container_exists "$resource_id" || die "Container $resource_id no longer exists"

container_running "$resource_id" || docker start "$resource_id" >&2

host_port="$(published_port "$resource_id" "$port")" || die "Docker published no host port for ${port}/tcp on $resource_id"
pairing_address="ws://127.0.0.1:${host_port}"

log "Restarting the Orca runtime, advertising $pairing_address"
recipe_json="$(docker exec \
  --env "ORCA_PORT=$port" \
  --env "ORCA_PROJECT_ROOT=$project_root" \
  --env "ORCA_PAIRING_ADDRESS=$pairing_address" \
  "$resource_id" orca-serve-recipe)"

image="$(docker container inspect -f '{{.Config.Image}}' "$resource_id")"
node -e '
const [raw, resourceId, image, hostPort] = process.argv.slice(1);
const served = JSON.parse(raw);
process.stdout.write(JSON.stringify({
  ...served,
  schemaVersion: 1,
  userData: { ...served.userData, provider: "docker", resourceId, image, hostPort: Number(hostPort) }
}));
' "$recipe_json" "$resource_id" "$image" "$host_port"
printf '\n'
