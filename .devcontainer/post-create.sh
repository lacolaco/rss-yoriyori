#!/bin/bash
set -e

# Clean up broken symlinks in .claude
find /root/.claude -xtype l -delete 2>/dev/null || true

# Download Gleam dependencies
[ -f gleam.toml ] && gleam deps download || true

# Authenticate GitHub CLI if needed
gh auth status || gh auth login --web
