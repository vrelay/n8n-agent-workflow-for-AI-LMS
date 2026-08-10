#!/usr/bin/env bash
# Build the production n8n image from the local ./n8n submodule (LMS UI patches included).
#
# n8n's official Dockerfile expects a pre-built `compiled/` tree, so this script:
#   1) runs `pnpm build:n8n` inside the submodule
#   2) `docker compose build n8n` → tags ai-lms/n8n:$N8N_VERSION
#
# Usage (from repo root):
#   ./docker/build-prod-image.sh
#   docker compose up -d

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f n8n/package.json ]]; then
  echo "error: n8n/ submodule missing — run: git submodule update --init" >&2
  exit 1
fi

# Prefer Node 24 from nvm when present (n8n needs >= 22.22)
if [[ -x "${HOME}/.nvm/versions/node/v24.15.0/bin/node" ]]; then
  export PATH="${HOME}/.nvm/versions/node/v24.15.0/bin:${PATH}"
fi

echo "==> Building production deploy tree (n8n/compiled)…"
(
  cd n8n
  corepack enable
  pnpm build:n8n
)

echo "==> Docker-building ai-lms/n8n (compose)…"
docker compose build n8n

echo "==> Done. Start with: docker compose up -d"
docker images "ai-lms/n8n" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}"
