#!/usr/bin/env bash
# Calls Gemini API with google_search grounding.
# Usage: ./gemini_research.sh <prompt-file>
# Prompt file is a plain-text file containing the user prompt.
# Stdout: raw JSON response from Gemini.
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

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "ERROR: GEMINI_API_KEY not set in $PROJECT_ROOT/.env" >&2
  exit 2
fi

MODEL="${GEMINI_MODEL:-gemini-2.5-pro}"
ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent"

# Build request body. Use python instead of jq because jq isn't always
# present and python3 is.
PROMPT_TEXT="$(cat "$PROMPT_FILE")"
REQUEST_BODY="$(
  python3 -c "
import json, sys
prompt = sys.stdin.read()
body = {
  'contents': [{'parts': [{'text': prompt}]}],
  'tools': [{'google_search': {}}],
  'generationConfig': {'temperature': 1.0}
}
print(json.dumps(body))
" <<< "$PROMPT_TEXT"
)"

# Call API. Timeout 5 minutes.
TMP_RESPONSE="$(mktemp /tmp/gemini_response.XXXXXX.json)"
HTTP_CODE=$(
  curl -sS -o "$TMP_RESPONSE" -w "%{http_code}" \
    --max-time 480 \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -X POST "$ENDPOINT" \
    -d "$REQUEST_BODY" \
  || echo "000"
)

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: Gemini API returned HTTP $HTTP_CODE" >&2
  cat "$TMP_RESPONSE" >&2
  rm -f "$TMP_RESPONSE"
  exit 1
fi

cat "$TMP_RESPONSE"
rm -f "$TMP_RESPONSE"
