#!/usr/bin/env bash
# Workspace setup for Orca: install the ui/ monorepo dependencies.
# Runs from the workspace checkout on Windows (Git Bash) and in the Linux
# per-workspace environment alike.
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
cd "$repo_root/ui"

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

if ! command -v pnpm >/dev/null 2>&1; then
  command -v corepack >/dev/null 2>&1 \
    || { echo "pnpm is missing and corepack is unavailable; install pnpm 11 first." >&2; exit 1; }
  # A root-owned Node prefix rejects the default shim location.
  corepack enable pnpm 2>/dev/null || {
    mkdir -p "$HOME/.local/bin"
    corepack enable --install-directory "$HOME/.local/bin"
    PATH="$HOME/.local/bin:$PATH"
    export PATH
  }
fi

pnpm install --frozen-lockfile
