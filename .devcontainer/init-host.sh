#!/bin/bash
# Runs on HOST before container build
# Resolves symlinks in ~/.claude config files for devcontainer

set -e

PROJECT_NAME=$(basename "$(pwd)")
DEST="/tmp/.claude-config-${PROJECT_NAME}"

rm -rf "$DEST"
mkdir -p "$DEST"

# Copy only config files (resolve symlinks)
for item in CLAUDE.md agents commands settings.json; do
  [ -e ~/.claude/"$item" ] && cp -rL ~/.claude/"$item" "$DEST/" 2>/dev/null || true
done

cp -L ~/.claude.json "$DEST/.claude.json" 2>/dev/null || true
