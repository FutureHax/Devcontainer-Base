#!/bin/bash

# Setup script to configure devcontainer using base configuration
# Projects can customize on top of the base

set -e

echo "🚀 Setting up base devcontainer configuration..."

# Check if we're in the right place
if [ ! -f ".gitmodules" ] || ! grep -q ".devcontainer-common" .gitmodules; then
    echo "❌ Error: .devcontainer-common submodule not found in .gitmodules"
    echo "Please run from your project root after adding the submodule:"
    echo "  git submodule add git@github.com:FutureHax/Devcontainer-Base.git .devcontainer-common"
    exit 1
fi

# Check if .devcontainer already exists
if [ -d ".devcontainer" ] && [ -f ".devcontainer/devcontainer.json" ]; then
    echo "📁 Existing .devcontainer found - will update to use base configuration"
    
    # Backup existing devcontainer.json
    cp .devcontainer/devcontainer.json .devcontainer/devcontainer.json.backup
    echo "💾 Backed up existing config to .devcontainer/devcontainer.json.backup"
    
    # Try to merge automatically if Node.js is available
    if command -v node >/dev/null 2>&1; then
        echo "🔧 Merging configurations automatically..."
        node .devcontainer-common/merge-devcontainer.js
        echo "✅ Configuration merged! Your customizations have been preserved."
    else
        # Fallback to manual instructions
        echo ""
        echo "⚠️  Please manually update your .devcontainer/devcontainer.json:"
        echo ""
        echo "1. Change the build section to reference the base:"
        echo '   "build": {'
        echo '     "dockerfile": "../.devcontainer-common/.devcontainer/Dockerfile",'
        echo '     "context": "../.devcontainer-common/.devcontainer"'
        echo '   },'
        echo ""
        echo "2. Update postCreateCommand to run base setup first:"
        echo '   "postCreateCommand": "cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh && <your-existing-command>"'
        echo ""
        echo "Your existing features, extensions, and settings will be preserved!"
    fi
    
else
    # Create new .devcontainer with base configuration
    echo "📁 Creating new .devcontainer directory..."
    mkdir -p .devcontainer
    
    echo "📄 Creating devcontainer.json with base configuration..."
    cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "${localWorkspaceFolderBasename} Dev Container",
  
  // Use the base Dockerfile from the submodule
  "build": {
    "dockerfile": "../.devcontainer-common/.devcontainer/Dockerfile",
    "context": "../.devcontainer-common/.devcontainer"
  },
  
  // Base features - add your own below
  "features": {
    // Project-specific features go here
  },
  
  // Base customizations - add your own below
  "customizations": {
    "vscode": {
      "settings": {
        // Project-specific settings go here
      },
      "extensions": [
        // Project-specific extensions go here
      ]
    }
  },
  
  // Environment variables - add your own below
  "containerEnv": {
    // Project-specific env vars go here
  },
  
  // Run base setup, then project-specific commands
  "postCreateCommand": "cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh",
  
  // Workspace configuration
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
}
EOF
    
    echo "✅ Created new devcontainer.json with base configuration"
    echo ""
    echo "📝 You can now customize your .devcontainer/devcontainer.json:"
    echo "   - Add project-specific VS Code extensions"
    echo "   - Add project-specific features"
    echo "   - Add project-specific settings"
    echo "   - The base Dockerfile and setup will be inherited automatically"
fi

echo ""
echo "📋 Base devcontainer provides:"
echo "   ✓ Multi-architecture support (amd64/arm64)"
echo "   ✓ Docker-in-Docker"
echo "   ✓ Node.js LTS with nvm"
echo "   ✓ Python 3.12"
echo "   ✓ Common VS Code extensions"
echo "   ✓ Zsh with Oh My Zsh"
echo "   ✓ Starship prompt"
echo ""
echo "Next steps:"
echo "1. Review/customize .devcontainer/devcontainer.json"
echo "2. Commit the changes:"
echo "   git add .devcontainer .gitmodules"
echo "   git commit -m 'Add base devcontainer configuration'"
echo "3. Reopen in VS Code with Dev Containers extension"