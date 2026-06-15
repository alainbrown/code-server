# Custom Code-Server

A highly customized, auto-updating Docker container based on [linuxserver/code-server](https://docs.linuxserver.io/images/docker-code-server/) that comes pre-loaded with a modern development environment.

## Built-in Tools

This container dynamically installs the latest stable versions of the following tools every night via GitHub Actions:

- **Node.js** (Latest Current release via NodeSource)
- **Python 3.12** (plus `pip` and `venv`)
- **Go** (Latest stable release fetched dynamically)
- **Rust** (Latest stable release via `rustup`, including `cargo`)
- **Git**
- **GitHub CLI** (`gh`)
- **Hugging Face CLI** (`hf`)
- **uv** (Extremely fast Python package and project manager)
- **Docker CLI** (Enables Docker-out-of-Docker when `/var/run/docker.sock` is mounted)
- **Utilities**: `ffmpeg`, `sqlite3`, `jq`, `tmux`, `htop`, `tree`, `zip`, `unzip`

## Usage

You can pull the latest image directly from the GitHub Container Registry:

```yaml
services:
  code-server:
    image: ghcr.io/alainbrown/code-server:latest
    container_name: code-server
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - PASSWORD=password # optional
      - SUDO_PASSWORD=password # optional
      - DEFAULT_WORKSPACE=/config/workspace # optional
    volumes:
      - /path/to/appdata/config:/config
      # Mount the Docker socket to use the built-in Docker CLI
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 8443:8443
    restart: unless-stopped
```

## Automated Builds

A GitHub Action is configured to automatically rebuild this image every night at midnight UTC to ensure all dependencies and tools are kept completely up-to-date. The images are tagged automatically with both `latest` and a datestamp (e.g., `YYYYMMDD`).
