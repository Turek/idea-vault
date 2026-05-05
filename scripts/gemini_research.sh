#!/usr/bin/env bash
# Calls Gemini API with google_search grounding.
# Usage: ./gemini_research.sh <prompt-file>
# Prompt file is a plain-text file containing the user prompt.
# Stdout: raw JSON response from Gemini (on success).
# Stderr: status messages.
# Exit 0 on success, non-zero on failure.
#
# Resilience:
#   - Retries the configured model on HTTP 429 / 503 with backoff
#     (10s then 30s).
#   - If those retries also fail, falls back once to gemini-2.5-flash
#     (unless that is already the configured model).
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

PRIMARY_MODEL="${GEMINI_MODEL:-gemini-2.5-pro}"
FALLBACK_MODEL="gemini-2.5-flash"

# Build request body once. Reused across all attempts.
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

# call_gemini <model> <out-file>
# Returns the HTTP status code on stdout. "000" on transport failure.
call_gemini() {
  local model="$1"
  local out="$2"
  local endpoint="https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent"
  curl -sS -o "$out" -w "%{http_code}" \
    --max-time 480 \
    -H "Content-Type: application/json" \
    -H "x-goog-api-key: ${GEMINI_API_KEY}" \
    -X POST "$endpoint" \
    -d "$REQUEST_BODY" \
    || echo "000"
}

# try_model <model>
# Up to three attempts (initial + two retries). Retries only on 429/503.
# On 200, prints response to stdout and returns 0.
# On any other final state, returns 1.
try_model() {
  local model="$1"
  local out
  out="$(mktemp /tmp/gemini_response.XXXXXX.json)"
  local backoffs=(10 30)
  local attempt=0
  local code

  while :; do
    code="$(call_gemini "$model" "$out")"
    if [[ "$code" == "200" ]]; then
      cat "$out"
      rm -f "$out"
      return 0
    fi

    if [[ "$code" == "429" || "$code" == "503" ]] && (( attempt < ${#backoffs[@]} )); then
      local wait="${backoffs[$attempt]}"
      echo "WARN: ${model} returned HTTP ${code}, retrying in ${wait}s..." >&2
      sleep "$wait"
      attempt=$((attempt + 1))
      continue
    fi

    echo "ERROR: ${model} returned HTTP ${code} (giving up on this model)" >&2
    cat "$out" >&2 || true
    rm -f "$out"
    return 1
  done
}

# Primary attempt.
if try_model "$PRIMARY_MODEL"; then
  exit 0
fi

# Fallback to Flash if it's not already the primary.
if [[ "$PRIMARY_MODEL" != "$FALLBACK_MODEL" ]]; then
  echo "INFO: falling back to ${FALLBACK_MODEL}..." >&2
  if try_model "$FALLBACK_MODEL"; then
    exit 0
  fi
fi

echo "ERROR: all Gemini attempts failed" >&2
exit 1
