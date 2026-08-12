#!/usr/bin/env bash
# Fail fast if the required n8n submodule was not cloned.
# Git cannot force --recurse-submodules on every clone; this is the local guard.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f n8n/package.json ]]; then
  cat >&2 <<'EOF'
error: n8n/ submodule is missing (required).

Fresh clone:
  git clone --recurse-submodules https://github.com/vrelay/n8n-agent-workflow-for-AI-LMS.git

Already cloned:
  git submodule update --init --recursive
  cd n8n && git checkout ai-lms && cd ..
EOF
  exit 1
fi
