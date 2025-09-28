#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo ">> Installing packages from various package managers..."

cd "$DIR"/../../ || exit

# Detect architecture
ARCH=$(uname -m)
echo ">>>> Detected architecture: $ARCH"

echo ">>>> Installing Go and Task..."

# Function to get latest Go version
get_latest_go_version() {
    # Fetch the latest stable Go version from the official Go website
    local latest_version=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version' | sed 's/go//')
    if [ -z "$latest_version" ]; then
        echo ">>> Failed to fetch latest Go version, using fallback"
        echo "1.22.0"  # Fallback version
    else
        echo "$latest_version"
    fi
}

# Function to get latest Task version
get_latest_task_version() {
    # Fetch the latest Task version from GitHub releases
    local latest_version=$(curl -s https://api.github.com/repos/go-task/task/releases/latest | jq -r '.tag_name')
    if [ -z "$latest_version" ]; then
        echo ">>> Failed to fetch latest Task version, using fallback"
        echo "v3.38.0"  # Fallback version
    else
        echo "$latest_version"
    fi
}

# Install Go and Task using direct downloads
install_go_and_task() {
    # Detect architecture
    local ARCH=$(dpkg --print-architecture)
    echo ">>> Architecture: $ARCH"
    
    # Get latest Go version
    local GO_VERSION=$(get_latest_go_version)
    echo ">>> Latest Go version: $GO_VERSION"
    local GO_ARCH=""
    case "$ARCH" in
        arm64|aarch64)
            GO_ARCH="arm64"
            ;;
        amd64|x86_64)
            GO_ARCH="amd64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Install Go
    echo ">>> Installing Go ${GO_VERSION} for ${GO_ARCH}..."
    local GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    wget -q -O /tmp/${GO_TAR} "https://go.dev/dl/${GO_TAR}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/${GO_TAR}
    rm /tmp/${GO_TAR}
    
    # Add Go to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi
    
    # Export for current session
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    
    # Verify Go installation
    echo ">>> Go installed:"
    /usr/local/go/bin/go version
    
    # Install Task
    echo ">>> Installing Task..."
    local TASK_VERSION=$(get_latest_task_version)
    echo ">>> Latest Task version: $TASK_VERSION"
    local TASK_ARCH=""
    case "$ARCH" in
        arm64|aarch64)
            TASK_ARCH="arm64"
            ;;
        amd64|x86_64)
            TASK_ARCH="amd64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Download and install Task
    local TASK_TAR="task_linux_${TASK_ARCH}.tar.gz"
    wget -q -O /tmp/${TASK_TAR} "https://github.com/go-task/task/releases/download/${TASK_VERSION}/${TASK_TAR}"
    sudo tar -C /usr/local/bin -xzf /tmp/${TASK_TAR} task
    sudo chmod +x /usr/local/bin/task
    rm /tmp/${TASK_TAR}
    
    # Verify Task installation
    echo ">>> Task installed:"
    /usr/local/bin/task --version
    
    echo ">>> Go and Task installation complete!"
}

# Run the installation
install_go_and_task || echo "❌ Failed to install Go and Task"
source ~/.bashrc

echo ">>>> Installing gitleaks..."
# Install gitleaks using direct download for better cross-platform support
install_gitleaks() {
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)
    
    # Map architecture names to gitleaks naming convention
    case "$ARCH" in
        x86_64)
            ARCH_NAME="x64"
            ;;
        aarch64|arm64)
            ARCH_NAME="arm64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Get latest version from GitHub API
    local LATEST_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "Failed to get latest version, using fallback"
        LATEST_VERSION="8.18.2"
    fi
    
    echo ">>> Installing gitleaks v$LATEST_VERSION for $OS $ARCH_NAME..."
    
    # Download and install
    local DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${LATEST_VERSION}/gitleaks_${LATEST_VERSION}_${OS}_${ARCH_NAME}.tar.gz"
    local TMP_DIR=$(mktemp -d)
    
    cd "$TMP_DIR"
    curl -L -o gitleaks.tar.gz "$DOWNLOAD_URL"
    tar -xzf gitleaks.tar.gz
    
    # Install to ~/.local/bin
    local INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    mv gitleaks "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/gitleaks"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> ~/.bashrc
    fi
    
    echo ">>> Gitleaks installed successfully"
}

# Run the installation
install_gitleaks || echo "❌ Failed to install gitleaks"
source ~/.bashrc

echo ">>>> Installing Starship prompt..."
# Install Starship using direct download
install_starship() {
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)
    
    # Map architecture names to starship naming convention
    case "$ARCH" in
        x86_64)
            ARCH_NAME="x86_64"
            ;;
        aarch64|arm64)
            ARCH_NAME="aarch64"
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Starship uses different OS naming
    case "$OS" in
        linux)
            # For aarch64, only musl builds are available
            if [ "$ARCH_NAME" = "aarch64" ]; then
                OS_NAME="unknown-linux-musl"
            else
                OS_NAME="unknown-linux-gnu"
            fi
            ;;
        darwin)
            OS_NAME="apple-darwin"
            ;;
        *)
            echo "Unsupported OS: $OS"
            return 1
            ;;
    esac
    
    # Get latest version from GitHub API
    local LATEST_VERSION=$(curl -s https://api.github.com/repos/starship/starship/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "Failed to get latest version, using fallback"
        LATEST_VERSION="1.23.0"
    fi
    
    echo ">>> Installing starship v$LATEST_VERSION for $ARCH_NAME-$OS_NAME..."
    
    # Download and install
    local DOWNLOAD_URL="https://github.com/starship/starship/releases/download/v${LATEST_VERSION}/starship-${ARCH_NAME}-${OS_NAME}.tar.gz"
    local TMP_DIR=$(mktemp -d)
    
    cd "$TMP_DIR" || return 1
    
    # Download with error checking
    if ! curl -L -o starship.tar.gz "$DOWNLOAD_URL"; then
        echo ">>> ERROR: Failed to download Starship from $DOWNLOAD_URL"
        cd - > /dev/null
        rm -rf "$TMP_DIR"
        return 1
    fi
    
    # Extract with error checking
    if ! tar -xzf starship.tar.gz; then
        echo ">>> ERROR: Failed to extract Starship archive"
        cd - > /dev/null
        rm -rf "$TMP_DIR"
        return 1
    fi
    
    # Install to ~/.local/bin
    local INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    
    # Move with error checking
    if ! mv starship "$INSTALL_DIR/"; then
        echo ">>> ERROR: Failed to move Starship to $INSTALL_DIR"
        cd - > /dev/null
        rm -rf "$TMP_DIR"
        return 1
    fi
    
    chmod +x "$INSTALL_DIR/starship"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> ~/.bashrc
    fi
    
    # Add starship init to bashrc if not already present
    if ! grep -q "starship init bash" ~/.bashrc; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
    
    # Also add to zshrc if zsh is available
    if [ -f ~/.zshrc ] && ! grep -q "starship init zsh" ~/.zshrc; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi
    
    # Verify installation
    if [ -x "$INSTALL_DIR/starship" ]; then
        echo ">>> Starship installed successfully"
        echo ">>> Version: $("$INSTALL_DIR/starship" --version 2>/dev/null || echo "Unable to get version")"
    else
        echo ">>> ERROR: Starship installation verification failed"
        return 1
    fi
}

# Run the installation
install_starship || echo "❌ Failed to install starship"
source ~/.bashrc

# All packages installed successfully

echo ">>>> Activating Python virtual environment..."
source .venv/bin/activate
echo ">>>>>> Python virtual environment activated."

echo ">>>> Installing Python packages from requirements.txt..."
pip install --upgrade --no-cache -r requirements.txt 
echo ">>>>>> Python packages installed."

echo ">> All packages installed."