# Using FutureHax Devcontainer-Base as Submodule

## In any new project:

1. **Add the submodule:**
   ```bash
   git submodule add git@github.com:FutureHax/Devcontainer-Base.git .devcontainer-common
   ```

2. **Copy this template to `.devcontainer/devcontainer.json`:**
   ```json
   {
     "name": "${localWorkspaceFolderBasename} Dev Container",
     "build": {
       "dockerfile": "../.devcontainer-common/.devcontainer/Dockerfile",
       "context": "../.devcontainer-common",
       "platforms": ["linux/amd64", "linux/arm64"]
     },
     "features": {
       "ghcr.io/devcontainers/features/docker-in-docker:2": {
         "version": "latest",
         "moby": true,
         "dockerDashComposeVersion": "v2"
       },
       "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {
         "version": "latest",
         "helm": "latest",
         "minikube": "none"
       },
       "ghcr.io/devcontainers/features/node:1": {
         "nodeGypDependencies": true,
         "version": "lts",
         "nvmVersion": "latest"
       }
     },
     "containerEnv": {
       "DOCKER_BUILDKIT": "1",
       "BUILDKIT_PROGRESS": "plain"
     },
     "mounts": ["source=devcontainer-bashhistory,target=/commandhistory,type=volume"],
     "postCreateCommand": "cd .devcontainer-common && sh .devcontainer/postCreateCommand.sh",
     "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
   }
   ```

3. **Commit:**
   ```bash
   git add .devcontainer .devcontainer-common .gitmodules
   git commit -m "Add common devcontainer"
   ```

## To update the base container:

```bash
cd .devcontainer-common
git pull origin main
cd ..
git add .devcontainer-common
git commit -m "Update devcontainer base"
```

That's it!
