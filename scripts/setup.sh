#!/usr/bin/env bash
# One-time local setup: create .env from .env.example, validate the workflows and
# check that Docker is available. Safe to re-run; an existing .env is never overwritten.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

info() { printf '==> %s\n' "$1"; }
warn() { printf 'warning: %s\n' "$1" >&2; }

if [[ -f .env ]]; then
  info ".env already exists, leaving it unchanged"
else
  cp .env.example .env
  chmod 600 .env
  if command -v openssl >/dev/null 2>&1; then
    key="$(openssl rand -hex 32)"
    tmp_file="$(mktemp)"
    sed "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=${key}/" .env >"$tmp_file"
    cat "$tmp_file" >.env
    rm -f "$tmp_file"
    info "created .env with a random N8N_ENCRYPTION_KEY (DRY_RUN=true)"
  else
    info "created .env; set N8N_ENCRYPTION_KEY yourself (openssl not found)"
  fi
fi

info "validating config and workflow JSON"
for file in config/*.json; do
  python3 -m json.tool "$file" >/dev/null || { echo "invalid JSON: $file" >&2; exit 1; }
done
python3 tools/validate_workflows.py workflows --env-example .env.example

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  info "docker compose found; start n8n with: docker compose up -d"
else
  warn "docker compose not found; install Docker Desktop or Docker Engine with the Compose plugin"
fi

cat <<'MSG'

Next steps (details in README.md):
  1. docker compose up -d, then open http://localhost:5678
  2. Add the "OpenAI account" and "LinkedIn account" credentials in n8n
  3. docker compose exec n8n n8n import:workflow --separate --input=/workflows
  4. Run the workflow with DRY_RUN=true and review the "Dry Run Log" output
MSG
