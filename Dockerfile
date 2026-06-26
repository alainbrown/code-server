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
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com | sh

# Install Node.js (Latest Stable) and pnpm
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g pnpm && \
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

# Install Claude and Codex CLIs
RUN npm install -g @anthropic-ai/claude-code && \
    curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh

# Install Playwright and its dependencies
RUN npm install -g playwright && \
    npx playwright install --with-deps && \
    rm -rf /var/lib/apt/lists/*
