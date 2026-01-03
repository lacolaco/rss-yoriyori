#!/bin/bash
# Runs on HOST before container build
# Resolves symlinks in ~/.claude so they work inside container

set -e

DEST="/tmp/.claude-resolved"

rm -rf "$DEST"
cp -rL ~/.claude "$DEST" 2>/dev/null || true
