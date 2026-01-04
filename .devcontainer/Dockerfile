FROM ghcr.io/gleam-lang/gleam:v1.13.0-erlang

# Claude Code + Terraform + gcloud CLI
RUN apt-get update && apt-get install -y nodejs npm curl gnupg unzip zsh inotify-tools \
    && npm install -g @anthropic-ai/claude-code \
    # Terraform
    && curl -fsSL https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    # gcloud CLI
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/* \
    && chsh -s /bin/zsh