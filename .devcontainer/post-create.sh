#!/bin/bash
set -e

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

# Authenticate GitHub CLI if needed
gh auth status || gh auth login --web
