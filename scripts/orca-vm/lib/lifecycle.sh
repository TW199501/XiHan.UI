# shellcheck shell=bash
# Shared parsing for the suspend/resume/destroy lifecycle payload Orca sends on
# stdin. Orca records a VM before create runs, so a payload may carry only
# instanceId; fall back to the name create would have used.

# shellcheck source=common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"

lifecycle_resource_id() {
  local payload="$1"
  node -e '
const payload = process.argv[1] ? JSON.parse(process.argv[1]) : {};
const direct = payload.recipeResult?.userData?.resourceId;
if (direct) { process.stdout.write(String(direct)); process.exit(0); }
const recipeId = String(payload.recipeId ?? process.env.ORCA_RECIPE_ID ?? "docker-sandbox")
  .replace(/[^a-zA-Z0-9_.-]/g, "-").slice(0, 48);
const instanceId = String(payload.instanceId ?? process.env.ORCA_VM_INSTANCE_ID ?? "")
  .replace(/[^a-zA-Z0-9_.-]/g, "-").slice(0, 60);
process.stdout.write(instanceId ? `orca-${recipeId}-${instanceId}` : "");
' "$payload"
}

read_lifecycle_payload() {
  cat
}
