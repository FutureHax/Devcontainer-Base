#!/bin/sh

DEV_CONTAINER_ROOT=$(dirname "$0")

# Detect architecture
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# All packages are now installed directly without Homebrew
echo "All dependencies will be installed directly without Homebrew"

# Run base dependencies installation
"$DEV_CONTAINER_ROOT"/installDependencies.sh

# Run project-specific dependencies if exists
# Get the workspace folder (two levels up from this script)
WORKSPACE_DIR=$(cd "$DEV_CONTAINER_ROOT/../.." && pwd)
PROJECT_INSTALL_SCRIPT="$WORKSPACE_DIR/.devcontainer/installDependencies.sh"
if [ -f "$PROJECT_INSTALL_SCRIPT" ]; then
    echo ""
    echo "Running project-specific dependencies installation..."
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    sh "$PROJECT_INSTALL_SCRIPT"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fi

# Starship configuration
if command -v starship >/dev/null 2>&1; then
    starship preset bracketed-segments -o ~/.config/starship.toml
fi

# Oh-my-zsh & plugins
sudo rm -rf /home/vscode/.oh-my-zsh
# shellcheck disable=SC1007
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | ZSH= zsh || true
zsh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
zsh -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'
sudo cp "$DEV_CONTAINER_ROOT"/zshrc /home/vscode/.zshrc

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Your dev container creation is complete!"

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Architecture: $ARCH"


echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

# Verify Docker installation works on this architecture
echo "Verifying Docker installation..."
if docker version > /dev/null 2>&1; then
    echo "✅ Docker is working correctly"
    
    # Set up Docker buildx for multi-platform builds
    echo "Setting up Docker buildx for multi-platform builds..."
    docker buildx create --name multiplatform --driver docker-container --bootstrap --use || true
    echo "✅ Docker buildx configured for multi-platform builds"
else
    echo "⚠️ WARNING: Docker is not working properly"
fi

# Final verification
# Note: We check the actual installation path because the PATH update from install.sh
# hasn't been loaded in the current shell session yet
echo ""
echo "🎉 Dev container setup complete!"
echo "📋 Summary:"
echo "   • Architecture: $ARCH"
echo "   • Docker: $(docker version >/dev/null 2>&1 && echo "✅ Working" || echo "❌ Issues")"
echo "   • Gitleaks: $([ -x "$HOME/.local/bin/gitleaks" ] && echo "✅ Installed" || echo "❌ Not found")"
echo "   • Starship: $([ -x "$HOME/.local/bin/starship" ] && echo "✅ Installed" || echo "❌ Not found")"
echo ""
echo "🔄 You may need to restart your terminal or reload your shell to use the installed tools"

# Git credential setup for GitLab
echo ""
echo "🔧 Configuring Git credentials..."


# --- GIT CONFIG SETUP ---
GIT_USER_EMAIL=${1:-ken@futurehax.com}
GIT_USER_NAME=${2:-Ken Kyger}

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "[INFO] Using default git config: $GIT_USER_NAME <$GIT_USER_EMAIL>"
  echo "[INFO] To override, run: ./postCreateCommand.sh <email> <name>"
fi

echo "Setting up git config"

# Check if git config is already set from mounted file
EXISTING_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
EXISTING_NAME=$(git config --global user.name 2>/dev/null || echo "")

if [ -n "$EXISTING_EMAIL" ] && [ -n "$EXISTING_NAME" ]; then
  echo "[INFO] Git config already exists: $EXISTING_NAME <$EXISTING_EMAIL>"
  echo "[INFO] Keeping existing configuration"
else
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global user.name "$GIT_USER_NAME"
fi

# Check if we're in WSL and configure credential manager
if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    echo "   • Detected WSL environment"
    
    # Try to use Windows credential manager if available
    if [ -f "/mnt/c/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe" ]; then
        git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
        echo "   ✅ Configured Windows Git Credential Manager"
    else
        # Fallback to cache
        git config --global credential.helper 'cache --timeout=3600'
        echo "   ⚠️  Windows Git Credential Manager not found, using cache helper"
    fi
fi

# Set up GitLab-specific configurations
git config --global credential.https://gitlab.futurehax.com.provider generic

echo ""
echo "🎉 Git configuration complete!"
