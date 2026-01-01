FROM ghcr.io/gleam-lang/gleam:v1.13.0-erlang

# Claude Code
RUN apt-get update && apt-get install -y nodejs npm \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*