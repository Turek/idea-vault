#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT="$(cd "$PLUGIN_DIR/.." && pwd)"

ZIP="$PARENT/idea-vault.zip"
PLUGIN_BUNDLE="$PARENT/idea-vault.plugin"

rm -f "$ZIP" "$PLUGIN_BUNDLE"
(cd "$PLUGIN_DIR" && zip -rq "$ZIP" . \
  -x ".git/*" ".gitignore" "*.DS_Store" ".DS_Store" \
     "scripts/build-plugin.sh" ".claude/*")
cp "$ZIP" "$PLUGIN_BUNDLE"

echo "Built: $ZIP"
echo "Built: $PLUGIN_BUNDLE"
