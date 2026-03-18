FROM quay.io/podman/stable

# Set environment variables for non-root user
ENV USER=root \
    UID=0 \
    GID=0 \
    HOME=/root

# Set environment variables for mountpoints
ENV CLAUDE_CONFIG_DIR=${HOME}/.claude \
    CODEX_CONFIG_DIR=${HOME}/.codex

# Install additional dependencies (base image already provides podman,
# fuse-overlayfs, git-core, crun, and configured container storage)
RUN dnf -y install \
    curl \
    python3 \
    sudo \
    nano \
    procps-ng \
    nodejs \
    npm \
    && dnf clean all

# Create config directory mount points
RUN mkdir -p ${CLAUDE_CONFIG_DIR} && chmod +x ${CLAUDE_CONFIG_DIR}
RUN mkdir -p ${CODEX_CONFIG_DIR} && chmod +x ${CODEX_CONFIG_DIR}
RUN chown -R ${UID}:${GID} ${CLAUDE_CONFIG_DIR} ${CODEX_CONFIG_DIR}

# Add Claude Code to PATH
ENV PATH="/root/.local/bin:${PATH}"

# Allow better editing experience via ctrl-g
ENV EDITOR=nano

# Set Claude Code config directory to the mounted volume
ENV CLAUDE_CLI_CONFIG_DIR=${CLAUDE_CONFIG_DIR}

# Copy and set entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

# Copy run-agent helper
COPY run-agent.sh /usr/local/bin/run-agent
RUN chmod +x /usr/local/bin/run-agent

# Set entrypoint to run updates on container start
ENTRYPOINT ["/usr/local/bin/entrypoint"]

# Install Claude Code CLI
ARG CLAUDE_CACHEBUST=1
RUN curl -fsSL https://claude.ai/install.sh | /bin/bash

# Install Codex CLI
RUN sudo npm install -g @openai/codex
