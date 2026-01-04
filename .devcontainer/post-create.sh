#!/bin/bash
set -e

# Copy Claude Code config files from host (symlinks resolved)
if [ -d /tmp/.claude-config ]; then
  mkdir -p /root/.claude
  for item in CLAUDE.md agents commands settings.json; do
    [ -e /tmp/.claude-config/"$item" ] && cp -r /tmp/.claude-config/"$item" /root/.claude/
  done
  [ -f /tmp/.claude-config/.claude.json ] && cp /tmp/.claude-config/.claude.json /root/.claude.json
fi

# Set up zsh history persistence
mkdir -p /commandhistory
touch /commandhistory/.zsh_history
if ! grep -q "HISTFILE=/commandhistory/.zsh_history" /root/.zshrc 2>/dev/null; then
  cat >> /root/.zshrc << 'EOF'
export HISTFILE=/commandhistory/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
EOF
fi

# Set up bash history persistence (fallback)
if ! grep -q "HISTFILE=/commandhistory/.bash_history" /root/.bashrc 2>/dev/null; then
  echo 'export HISTFILE=/commandhistory/.bash_history' >> /root/.bashrc
  echo 'export HISTSIZE=10000' >> /root/.bashrc
  echo 'export HISTFILESIZE=10000' >> /root/.bashrc
fi
touch /commandhistory/.bash_history

# Download Gleam dependencies
[ -f gleam.toml ] && gleam deps download || true

# Set up git hooks
if [ -d .githooks ]; then
  git config core.hooksPath .githooks
  echo "✓ Git hooks configured (.githooks)"
fi

# Authenticate GitHub CLI if needed
gh auth status || gh auth login --web
