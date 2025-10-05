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
    wget -q -O /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    
    # Add Go to PATH if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin
    
    # Verify Go installation
    echo ">>> Go installed:"
    /usr/local/go/bin/go version
    
    # Get latest Task version
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
            echo "Unsupported architecture for Task: $ARCH"
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
    local ARCHIVE="gitleaks_${LATEST_VERSION}_${OS}_${ARCH_NAME}.tar.gz"
    wget -q -O /tmp/${ARCHIVE} "https://github.com/gitleaks/gitleaks/releases/download/v${LATEST_VERSION}/${ARCHIVE}"
    
    if [ ! -f "/tmp/${ARCHIVE}" ]; then
        echo ">>> Failed to download gitleaks"
        return 1
    fi
    
    # Extract and install
    sudo tar -C /usr/local/bin -xzf /tmp/${ARCHIVE} gitleaks
    sudo chmod +x /usr/local/bin/gitleaks
    rm /tmp/${ARCHIVE}
    
    # Verify installation
    if ! command -v gitleaks &> /dev/null; then
        echo ">>> gitleaks command not found after installation"
        return 1
    fi
    
    echo ">>> Gitleaks installed successfully"
}

# Run the installation
install_gitleaks || echo "❌ Failed to install gitleaks"
source ~/.bashrc

echo ">>>> Installing Flux CLI..."
# Install Flux CLI using official install script
install_flux() {
    echo ">>> Installing Flux CLI..."
    curl -s https://fluxcd.io/install.sh | sudo bash
    
    # Verify installation
    if command -v flux &> /dev/null; then
        echo ">>> Flux installed successfully:"
        flux --version
        return 0
    else
        echo ">>> Failed to install Flux"
        return 1
    fi
}

# Run the installation
install_flux || echo "❌ Failed to install Flux"

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
        LATEST_VERSION="1.17.1"
    fi
    
    echo ">>> Installing starship v$LATEST_VERSION for $ARCH_NAME-$OS_NAME..."
    
    # Download and install
    local TAR="starship-${ARCH_NAME}-${OS_NAME}.tar.gz"
    wget -q -O /tmp/${TAR} "https://github.com/starship/starship/releases/download/v${LATEST_VERSION}/${TAR}"
    
    if [ ! -f "/tmp/${TAR}" ]; then
        echo ">>> Failed to download starship"
        return 1
    fi
    
    # Extract and install
    sudo tar -C /usr/local/bin -xzf /tmp/${TAR} starship
    sudo chmod +x /usr/local/bin/starship
    rm /tmp/${TAR}
    
    # Verify installation
    if ! command -v starship &> /dev/null; then
        echo ">>> starship command not found after installation"
        return 1
    fi
    
    # Initialize starship for the current user
    if ! grep -q "starship init" ~/.bashrc; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
    if ! grep -q "starship init" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc 2>/dev/null || true
    fi
    
    echo ">>> Starship installed successfully:"
    /usr/local/bin/starship --version
}

# Run the installation
install_starship || echo "❌ Failed to install Starship"

# Only source bashrc if we're running in bash
if [ -n "$BASH_VERSION" ]; then
    source ~/.bashrc
fi

# Additional tool installations can be added here following the same pattern

# Requirements.txt installation
echo ">>>> Installing Python packages from requirements.txt..."

# Check if running in a devcontainer and the requirements file exists
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt || echo "❌ Failed to install Python packages"
else
    echo ">>>> No requirements.txt found, skipping Python package installation"
fi

echo ">> All package installations complete!"