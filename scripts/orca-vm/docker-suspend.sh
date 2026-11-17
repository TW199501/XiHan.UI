#!/usr/bin/env bash
# Suspend: stop the container. Resume restarts it and re-emits recipe JSON.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/lifecycle.sh
. "$script_dir/lib/lifecycle.sh"

require_cmd node
require_docker_daemon

payload="$(read_lifecycle_payload)"
resource_id="$(lifecycle_resource_id "$payload")"
[ -n "$resource_id" ] || die "No resource id in the lifecycle payload"

container_exists "$resource_id" || die "Container $resource_id no longer exists"
docker stop --timeout 10 "$resource_id" >&2
log "Suspended $resource_id"
