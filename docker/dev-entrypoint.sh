#!/usr/bin/env bash
set -euo pipefail

cd /app

corepack enable

if [[ ! -d node_modules ]]; then
  echo "[dev] node_modules missing — running pnpm install (first run is slow)..."
  pnpm install
fi

# editor-ui / cli dist may be missing on a fresh clone
if [[ ! -d packages/cli/dist ]]; then
  echo "[dev] packages/cli/dist missing — running pnpm build (first run is slow)..."
  pnpm build
fi

# Default: start n8n backend (serves built editor UI on :5678).
# Override compose command for Vite HMR, e.g. pnpm --filter n8n-editor-ui dev
if [[ $# -eq 0 ]]; then
  exec pnpm start
fi
exec "$@"
