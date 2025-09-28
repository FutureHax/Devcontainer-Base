# FutureHax Devcontainer Base

Base devcontainer configuration for consistent development environments.

## Setup

1. **Add this submodule to your project:**
   ```bash
   git submodule add git@github.com:FutureHax/Devcontainer-Base.git .devcontainer-common
   ```

2. **Create `.devcontainer-specific/devcontainer.json`:**
   ```json
   {
     // Project-specific features to add to base
     "features": {
       // Your features here
     }
   }
   ```

3. **Build the devcontainer:**
   ```bash
   node .devcontainer-common/build-devcontainer.js
   ```

4. **Add to `.gitignore`:**
   ```
   .devcontainer/
   ```

## Project Structure

```
your-project/
├── .devcontainer-common/     # This submodule (base config)
├── .devcontainer-specific/   # Your project's config
│   ├── devcontainer.json    # Project features/settings
│   └── postCreateCommand.sh # Project-specific setup
└── .devcontainer/           # Generated (don't commit)
```

## What's Included

- 🐳 Docker-in-Docker
- 📦 Node.js LTS  
- 🐍 Python 3.12
- ☸️ Kubernetes tools
- 🔧 VS Code extensions
- 🐚 Zsh + Oh My Zsh
- ⭐ Starship prompt

## Customization

Your `.devcontainer-specific/postCreateCommand.sh` runs automatically after base setup.