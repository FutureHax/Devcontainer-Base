# FutureHax Devcontainer Base

A reusable base devcontainer configuration that projects can build upon.

## Quick Setup

1. **Add the submodule:**
   ```bash
   git submodule add git@github.com:FutureHax/Devcontainer-Base.git .devcontainer-common
   ```

2. **Run the setup script:**
   ```bash
   ./.devcontainer-common/setup-devcontainer.sh
   ```

3. **Commit:**
   ```bash
   git add .devcontainer .devcontainer-common .gitmodules
   git commit -m "Add base devcontainer configuration"
   ```

## What You Get

The base devcontainer provides:
- 🖥️ Multi-architecture support (amd64/arm64)
- 🐳 Docker-in-Docker
- ☸️ Kubernetes tools (kubectl, helm)
- 📦 Node.js LTS with nvm
- 🐍 Python 3.12
- 🔧 Common VS Code extensions
- 🐚 Zsh with Oh My Zsh
- ⭐ Starship prompt

## Customization

Your project's `.devcontainer/devcontainer.json` can add:
- Additional VS Code extensions
- Project-specific features
- Custom environment variables
- Additional post-create commands

Your project can also include:
- `.devcontainer/installDependencies.sh` - Will run after base dependencies are installed
- Any other scripts or configuration files needed by your project

The setup script will merge your existing configuration with the base, preserving all your customizations.

## To update the base container:

```bash
cd .devcontainer-common
git pull origin main
cd ..
git add .devcontainer-common
git commit -m "Update devcontainer base"
```

That's it!
