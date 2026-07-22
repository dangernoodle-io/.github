#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="${PLUGIN_NAME:?}"
REF="${REF:?}"

git clone git@github.com:dangernoodle-io/dangernoodle-marketplace.git marketplace-repo
cd marketplace-repo || exit 1

git config user.name "dangernoodle build bot"
git config user.email "build-bot@dangernoodle.io"

# Update marketplace.json: set source.ref for matching plugin.
# jq --arg passes values as data, never parsed as jq program text.
jq --arg name "$PLUGIN_NAME" --arg ref "$REF" \
  '(.plugins[] | select(.name == $name) | .source.ref) |= $ref' \
  .claude-plugin/marketplace.json > marketplace.json.tmp
mv marketplace.json.tmp .claude-plugin/marketplace.json

# Check if there are changes
if git diff --quiet .claude-plugin/marketplace.json; then
  echo "No changes to marketplace.json for $PLUGIN_NAME"
  exit 0
fi

git add .claude-plugin/marketplace.json
git commit -S -m "chore: bump $PLUGIN_NAME to $REF"
git push origin main
