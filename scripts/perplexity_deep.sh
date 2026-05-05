#!/usr/bin/env bash
# Calls Perplexity Sonar Deep Research.
# Usage: ./perplexity_deep.sh <prompt-file>
# Stdout: raw JSON response from Perplexity.
# Stderr: status messages.
# Exit 0 on success, non-zero on failure.
#
# This script lives at ${CLAUDE_PLUGIN_ROOT}/scripts/ but reads .env from
# the user's project directory ($PWD), not from the plugin folder.

set -euo pipefail

PROMPT_FILE="${1:-}"
if [[ -z "$PROMPT_FILE" || ! -f "$PROMPT_FILE" ]]; then
  echo "ERROR: prompt file missing or not found: $PROMPT_FILE" >&2
  exit 2
fi

# Source .env from the user's project (current working directory).
PROJECT_ROOT="${IDEA_VAULT_PROJECT_ROOT:-$PWD}"
if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/.env"
  set +a
else
  echo "ERROR: .env not found at $PROJECT_ROOT/.env" >&2
  echo "Run /idea-vault:init in your project, then 'cp .env.example .env' and fill in keys." >&2
  exit 2
fi

if [[ -z "${PERPLEXITY_API_KEY:-}" ]]; then
  echo "ERROR: PERPLEXITY_API_KEY not set in $PROJECT_ROOT/.env" >&2
  exit 2
fi

MODEL="${PERPLEXITY_MODEL:-sonar-deep-research}"
ENDPOINT="https://api.perplexity.ai/chat/completions"

PROMPT_TEXT="$(cat "$PROMPT_FILE")"
REQUEST_BODY="$(
  python3 -c "
import json, sys, os
prompt = sys.stdin.read()
model = os.environ.get('PERPLEXITY_MODEL_OVERRIDE', '$MODEL')
body = {
  'model': model,
  'messages': [
    {'role': 'system', 'content': 'You are a thorough market research analyst. Cite real sources. Be honest about uncertainty.'},
    {'role': 'user', 'content': prompt}
  ]
}
print(json.dumps(body))
" <<< "$PROMPT_TEXT"
)"

# Deep research can take minutes. Timeout 15 minutes.
TMP_RESPONSE="$(mktemp /tmp/perplexity_response.XXXXXX.json)"
HTTP_CODE=$(
  curl -sS -o "$TMP_RESPONSE" -w "%{http_code}" \
    --max-time 900 \
    -H "Authorization: Bearer ${PERPLEXITY_API_KEY}" \
    -H "Content-Type: application/json" \
    -X POST "$ENDPOINT" \
    -d "$REQUEST_BODY" \
  || echo "000"
)

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: Perplexity API returned HTTP $HTTP_CODE" >&2
  cat "$TMP_RESPONSE" >&2
  rm -f "$TMP_RESPONSE"
  exit 1
fi

cat "$TMP_RESPONSE"
rm -f "$TMP_RESPONSE"
