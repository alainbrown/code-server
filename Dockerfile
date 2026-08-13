FROM lscr.io/linuxserver/code-server:latest

# Set environment variables for non-interactive apt and global tool paths
ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/opt/rust \
    CARGO_HOME=/opt/rust \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PATH=${PATH}:/usr/local/go/bin:/opt/rust/bin

# Update apt and install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    openssh-server \
    ssh-import-id \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    build-essential \
    jq \
    ffmpeg \
    sqlite3 \
    tmux \
    htop \
    tree \
    zip \
    unzip \
    xz-utils \
    bubblewrap \
    && rm -f /etc/ssh/ssh_host_* \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com | sh

# Install Node.js (Latest Stable) and pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm vercel && \
    rm -rf /var/lib/apt/lists/*

# Install Go (dynamically grabs the latest version)
RUN GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1) && \
    wget https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz && \
    rm ${GO_VERSION}.linux-amd64.tar.gz

# Install Rust globally
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path && \
    chmod -R a+w /opt/rust

# Install GitHub CLI (gh)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install gh -y && \
    rm -rf /var/lib/apt/lists/*

# Install Hugging Face CLI and uv globally via pipx
RUN pipx install huggingface-hub && \
    pipx install uv && \
    chmod -R a+rx /opt/pipx

# Install Claude, Codex, and Pi CLIs
RUN npm install -g @anthropic-ai/claude-code && \
    npm install -g --ignore-scripts @earendil-works/pi-coding-agent && \
    curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

# Install Playwright and its dependencies
RUN npm install -g playwright && \
    npx playwright install --with-deps && \
    rm -rf /var/lib/apt/lists/*

# Install Stripe CLI
RUN npm install -g @stripe/cli

# Install Herdr (agent multiplexer)
RUN curl -fsSL https://herdr.dev/install.sh | sh

# Install terminal editors: Helix (modal, built-in LSP) and micro (mouse + ctrl-key bindings)
RUN HELIX_VERSION=$(curl -sL https://api.github.com/repos/helix-editor/helix/releases/latest | jq -r .tag_name) && \
    curl -sL "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" | tar -xJ -C /opt && \
    mv /opt/helix-${HELIX_VERSION}-x86_64-linux /opt/helix && \
    ln -s /opt/helix/hx /usr/local/bin/hx && \
    MICRO_VERSION=$(curl -sL https://api.github.com/repos/zyedidia/micro/releases/latest | jq -r .tag_name) && \
    curl -sL "https://github.com/zyedidia/micro/releases/download/${MICRO_VERSION}/micro-${MICRO_VERSION#v}-linux64-static.tar.gz" | tar -xz -C /opt && \
    mv /opt/micro-${MICRO_VERSION#v} /opt/micro && \
    ln -s /opt/micro/micro /usr/local/bin/micro

# Helix ships its grammars/queries in a runtime dir that must be discoverable
ENV HELIX_RUNTIME=/opt/helix/runtime

# SSH support (optional, activated by setting GITHUB_USER)
COPY root/custom-cont-init.d/50-sshd-setup /custom-cont-init.d/50-sshd-setup
COPY root/custom-services.d/sshd /custom-services.d/sshd
RUN chmod 0755 /custom-cont-init.d/50-sshd-setup /custom-services.d/sshd
EXPOSE 22
