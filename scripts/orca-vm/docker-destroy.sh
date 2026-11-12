#!/usr/bin/env bash
# Destroy: remove the container. Images and the state file are left alone.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/lifecycle.sh
. "$script_dir/lib/lifecycle.sh"

require_cmd node
require_docker_daemon

payload="$(read_lifecycle_payload)"
resource_id="$(lifecycle_resource_id "$payload")"
[ -n "$resource_id" ] || die "No resource id in the lifecycle payload"

if ! container_exists "$resource_id"; then
  log "Container $resource_id is already gone"
  exit 0
fi

docker rm --force "$resource_id" >&2
log "Destroyed $resource_id"
