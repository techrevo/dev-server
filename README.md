# 🌌 Dev Server

A customized version of [code-server](https://github.com/coder/code-server), designed for developers who need a remote, persistent, and multi-language environment

[![Build and Publish](https://github.com/techrevo/dev-server/actions/workflows/publish.yml/badge.svg)](https://github.com/techrevo/dev-server/actions)
![Docker Pulls](https://img.shields.io/docker/pulls/techrevo/dev-server?style=flat-square)
![Multi-Arch](https://img.shields.io/badge/platform-amd64%20%7C%20arm64-blue)

## ✨ Features

- 🚀 Lightweight Image: only essential tools are baked in; languages are provisioned on-demand.
- 👤 Real Custom User: no more root-owned files. Runs as a standard user with a real home directory.
- 🔐 Secure by Default: password-protected sessions (auto-generated or custom).
- 📦 Modern Tooling:
  - 🐍 Python via uv.
  - 🐹 Go via official binary installer.
  - 🟢 Node.js via fnm.
  - ☕ Java via SDKMAN!.
  - 🛠️ C/C++ via build-essential or specific GCC/Clang versions.

---

## 🚀 Quick Start

### Docker Compose (Recommended)

Using Docker Compose is the best way to ensure persistence of your languages and configurations.

```yaml
services:
  dev-server:
    container_name: dev-server
    image: ghcr.io/techrevo/dev-server:latest
    restart: unless-stopped
    ports:
      - 8080:8080
    environment:
      - DEV_USER=coder            # Your custom username
      - PASSWORD=mysecretpass     # Optional: if omitted, check logs for generated pass
      - INSTALL_PYTHON=3.14       # "true" (3.14), "false", or version
      - INSTALL_NODE=true         # "true" (lts), "false", or version
      - INSTALL_GO=true           # "true" (latest), "false", or version
      - INSTALL_JAVA=25-open      # SDKMAN identifier
      - INSTALL_CPP=true          # "true" (build-essential), "false", or version (e.g. "12")
    volumes:
      - ./data:/home/coder        # Persistent home (includes projects, extensions, and configs)
```

### Docker Run

```bash
docker run -d \
  --name dev-server \
  -p 8080:8080 \
  -e DEV_USER=coder \
  -e PASSWORD=mysecretpass \
  -e INSTALL_PYTHON=3.14 \
  -e INSTALL_NODE=lts \
  -e INSTALL_GO=true \
  -e INSTALL_JAVA=25-open \
  -e INSTALL_CPP=true \
  -v $/data:/home/coder \
  ghcr.io/techrevo/dev-server:latest
```

> ⚠️ **Note**: Your code will be located in /home/$DEV_USER/projects. This directory is automatically created and kept persistent if you mount the home volume.

## 🔧 Environment variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DEV_USER` | The username for the session and home dir | `coder` |
| `PASSWORD` | Password for web login | *Randomly generated* |
| `INSTALL_PYTHON` | Python version to install via `uv` | `false` |
| `INSTALL_GO` | Go version (official binaries) | `false` |
| `INSTALL_NODE` | Node version to install via `fnm` | `false` |
| `INSTALL_JAVA` | Java version to install via `SDKMAN!` | `false` |
| `INSTALL_CPP` | C/C++ toolchain (GCC/Clang) | `false` |

## 🛠️ Customization

This project is designed to be forked! If you want to add more default tools, simply modify the entrypoint.sh or the Dockerfile and the GitHub Action will automatically build your custom version.

### How to add a new language
1. Add a new install_interpreter case in entrypoint.sh.
2. Add the corresponding INSTALL_* variable to your environment.
3. Push your changes and let GitHub Actions do the heavy lifting.

## 📄 License

Distributed under the MIT License. See LICENSE for more information.