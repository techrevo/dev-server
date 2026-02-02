#!/bin/bash

DEV_USER=${DEV_USER:-coder}
HOME_DIR="/home/$DEV_USER"

if ! id "$DEV_USER" &>/dev/null; then
    echo "Creating user $DEV_USER..."
    useradd -m -s /usr/bin/bash "$DEV_USER"
    usermod -aG sudo "$DEV_USER"
    echo "$DEV_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "PS1='\[\e[1;32m\]\u@dev-server\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '" >> "$HOME_DIR/.bashrc"
fi

export HOME="$HOME_DIR"
export XDG_CONFIG_HOME="$HOME_DIR/.config"
export XDG_DATA_HOME="$HOME_DIR/.local/share"

mkdir -p "$HOME_DIR/projects" "$HOME_DIR/.config" "$HOME_DIR/.local/share"

NEW_PATH=""

install_language_deps() {
    local language=$1
    local version=$2

    if [ "$version" = "false" ] || [ -z "$version" ]; then return; fi

    case $language in
        python) [[ -d "$HOME_DIR/.local/share/uv" ]] && echo "Python (uv) already managed. Skipping install." && return ;;
        go) [[ -d "$HOME_DIR/.go" ]] && echo "Go already managed. Skipping install." && return ;;
        node)   [[ -d "$HOME_DIR/.fnm" ]] && echo "Node (fnm) already managed. Skipping install." && return ;;
        java)   [[ -d "$HOME_DIR/.sdkman" ]] && echo "Java (sdkman) already managed. Skipping install." && return ;;
    esac
    
    echo "Installing $language ($version)..."
    case $language in
        python) 
            curl -LsSf https://astral.sh/uv/install.sh | sh
            source $HOME/.local/bin/env 2>/dev/null || true
            uv python install ${version/true/3.14}
            export NEW_PATH="$HOME/.local/share/uv/versions/python/${version/true/3.14}/bin:$NEW_PATH"
            ;;
        go)
            ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
            GO_VERSION=$(if [ "$version" = "true" ]; then curl -s https://go.dev/VERSION?m=text | head -n 1; else echo "go$version"; fi)
            curl -LO "https://go.dev/dl/${GO_VERSION}.linux-${ARCH}.tar.gz"
            tar -C "$HOME_DIR" -xzf "${GO_VERSION}.linux-${ARCH}.tar.gz"
            rm "${GO_VERSION}.linux-${ARCH}.tar.gz"
            export NEW_PATH="$HOME_DIR/go/bin:$NEW_PATH"
            ;;
        node)
            curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.fnm" --skip-shell
            export NEW_PATH="$HOME/.fnm:$NEW_PATH"
            fnm install ${version/true/--lts}
            export NEW_PATH="$HOME_DIR/.fnm/aliases/default/bin:$NEW_PATH"
            ;;
        java)
            if [ ! -d "$HOME/.sdkman" ]; then
                curl -s "https://get.sdkman.io" | bash
            fi
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            sdkman install java ${version/true/25-open}
            export NEW_PATH="$HOME/.sdkman/candidates/java/current/bin:$NEW_PATH"
            ;;
        cpp)
            if [[ "$version" != "true" ]]; then
                apt-get update && apt-get install -y gcc-"$version" g++-"$version" || apt-get install -y clang-"$version"
            else
                apt-get update && apt-get install -y build-essential clang
            fi
    esac
}

install_language_deps "python" "$INSTALL_PYTHON"
install_language_deps "go"      "$INSTALL_GO"
install_language_deps "node"   "$INSTALL_NODE"
install_language_deps "java"   "$INSTALL_JAVA"
install_language_deps "cpp"    "$INSTALL_CPP"

[[ -s "$HOME_DIR/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME_DIR/.sdkman/bin/sdkman-init.sh"

chown -R "$DEV_USER:$DEV_USER" "$HOME_DIR"

PASSWORD=${PASSWORD:-$(openssl rand -base64 12)}
CONTAINER_IP=$(hostname -I | awk '{print $1}')
NEW_PATH=$(echo "$NEW_PATH" | sed 's/::/:/g; s/:$//; s/^://')

echo "--------------------------------------------"
echo "  dev-server is starting!"
echo "  URL: http://$CONTAINER_IP:8080"
echo "  Password: $PASSWORD"
echo "--------------------------------------------"

exec sudo -u "$DEV_USER" -i bash -c "
    export PATH=\"$NEW_PATH:\$PATH\";
    export PASSWORD=${PASSWORD};
    code-server --bind-addr 0.0.0.0:8080 --auth password \"$HOME_DIR/projects\""