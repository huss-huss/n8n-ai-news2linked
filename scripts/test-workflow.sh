#!/usr/bin/env bash
# Pre-flight checks before enabling the workflow:
#   - each enabled feed in config/news-sources.json answers with HTTP 2xx
#   - optional: OPENAI_API_KEY (environment variable, not stored anywhere) is accepted,
#     using GET /v1/models, which costs nothing
# Usage: ./scripts/test-workflow.sh            or   OPENAI_API_KEY=... ./scripts/test-workflow.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
failures=0

echo "Checking enabled RSS feeds..."
while IFS= read -r feed; do
  status="$(curl --silent --location --output /dev/null --max-time 15 \
    --user-agent 'n8n-ai-news2linked feed check' --write-out '%{http_code}' "$feed" || true)"
  if [[ "$status" =~ ^2 ]]; then
    echo "  ok   $status $feed"
  else
    echo "  FAIL $status $feed"
    failures=$((failures + 1))
  fi
done < <(python3 -c 'import json; [print(s["url"]) for s in json.load(open("config/news-sources.json"))["sources"] if s["enabled"]]')

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "Checking OpenAI API key..."
  # Header passed on stdin so the key never appears in the process list.
  status="$(printf 'Authorization: Bearer %s\n' "$OPENAI_API_KEY" \
    | curl --silent --output /dev/null --max-time 15 --header @- --write-out '%{http_code}' \
      https://api.openai.com/v1/models || true)"
  if [[ "$status" == "200" ]]; then
    echo "  ok   key accepted"
  else
    echo "  FAIL OpenAI returned HTTP $status"
    failures=$((failures + 1))
  fi
else
  echo "OPENAI_API_KEY not set in the environment; skipping the OpenAI check."
fi

if ((failures > 0)); then
  echo "$failures check(s) failed" >&2
  exit 1
fi
echo "All checks passed."
