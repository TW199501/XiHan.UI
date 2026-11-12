#!/usr/bin/env bash
# Build the base image every per-workspace environment boots from.
# Run this by hand, not through orca.yaml. Logs go to stderr; stdout carries
# only the merged state JSON.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib/common.sh
. "$script_dir/lib/common.sh"

require_cmd node
require_cmd gh
require_docker_daemon

base_name="$(env_value ORCA_BASE_NAME baseName 'orca-xihan-ui')"
base_image="$(env_value ORCA_BASE_IMAGE authSourceSnapshotId "${base_name}:base")"
server_version="$(env_value ORCA_SERVER_VERSION orcaServerVersion 'v1.4.256')"
repo_url="$(env_value ORCA_REPO_URL repoUrl 'https://github.com/TW199501/XiHan.UI.git')"
repo_ref="$(env_value ORCA_REPO_REF repoRef 'dev')"
project_root="$(env_value ORCA_PROJECT_ROOT projectRoot '/home/orca/XiHan.UI')"
port="$(env_value ORCA_PORT port '6768')"

tarball="orca-server-linux-x64.tar.gz"
sums="orca-server-sha256sums.txt"

cleanup_context() {
  rm -f "$script_dir/$tarball" "$script_dir/$sums"
}
trap cleanup_context EXIT

log "Downloading Orca server $server_version into the build context"
gh release download "$server_version" --repo stablyai/orca \
  --pattern "$tarball" --pattern "$sums" --dir "$script_dir" --clobber >&2

log "Verifying the tarball checksum"
(cd "$script_dir" && grep " \*\{0,1\}${tarball}\$" "$sums" | sed 's/\*//' | sha256sum --check --strict -) >&2

log "Building $base_image (this takes a while on the first run)"
docker build \
  --tag "$base_image" \
  --build-arg "ORCA_SERVER_TARBALL=$tarball" \
  --build-arg "REPO_URL=$repo_url" \
  --build-arg "REPO_REF=$repo_ref" \
  --build-arg "PROJECT_ROOT=$project_root" \
  --label "orca.base-name=$base_name" \
  --label "orca.server-version=$server_version" \
  --file "$script_dir/Dockerfile" \
  "$script_dir" >&2

image_exists "$base_image" || die "Docker reported success but $base_image does not exist"

state_merge "$(node -e 'const [b,i,v,u,r,p,port]=process.argv.slice(1);
process.stdout.write(JSON.stringify({baseName:b, authSourceSnapshotId:i, orcaServerVersion:v,
  repoUrl:u, repoRef:r, projectRoot:p, port:Number(port)}))' \
  "$base_name" "$base_image" "$server_version" "$repo_url" "$repo_ref" "$project_root" "$port")"
