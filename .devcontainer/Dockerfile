# Multi-arch base image that supports both ARM64 and AMD64
# Using Debian Bullseye (Microsoft's stable dev container base image)
FROM --platform=$TARGETPLATFORM mcr.microsoft.com/devcontainers/base:bullseye

ARG USERNAME=vscode
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Display build platform information
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM"

# Create command history directory with proper permissions
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.bashrc"

# Install basic dependencies for development
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    file \
    git \
    procps \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Ensure proper permissions
USER vscode