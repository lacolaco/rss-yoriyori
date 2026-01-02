#!/bin/bash
set -e

# Set up bash history persistence
if ! grep -q "HISTFILE=/commandhistory/.bash_history" /root/.bashrc 2>/dev/null; then
  echo 'export HISTFILE=/commandhistory/.bash_history' >> /root/.bashrc
  echo 'export HISTSIZE=10000' >> /root/.bashrc
  echo 'export HISTFILESIZE=10000' >> /root/.bashrc
fi
touch /commandhistory/.bash_history

# Clean up broken symlinks in .claude
find /root/.claude -xtype l -delete 2>/dev/null || true

# Download Gleam dependencies
[ -f gleam.toml ] && gleam deps download || true

# Authenticate GitHub CLI if needed
gh auth status || gh auth login --web
