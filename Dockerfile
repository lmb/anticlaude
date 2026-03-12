FROM ubuntu:latest

RUN userdel -r ubuntu

# Set environment variables for build
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables for non-root user
ENV USER=anticlaude \
    UID=1000 \
    GID=1000 \
    HOME=/home/anticlaude

# Set environment variables for mountpoints
ENV CLAUDE_CONFIG_DIR=${HOME}/.claude \
    WORKSPACE=${HOME}/workspace

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    python3 \
    sudo \
    nano \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with passwordless sudo
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -d ${HOME} -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER}

# Create config directory mount point
RUN mkdir -p ${CLAUDE_CONFIG_DIR} && chmod +x ${CLAUDE_CONFIG_DIR}
RUN mkdir -p ${WORKSPACE} && chmod +x ${WORKSPACE}
RUN chown -R ${UID}:${GID} ${WORKSPACE} ${CLAUDE_CONFIG_DIR}

# Switch to non-root user
USER ${USER}

# Add Claude Code to PATH
ENV PATH="${HOME}/.local/bin:${PATH}"

# Allow better editing experience via ctrl-g
ENV EDITOR=nano

# Set Claude Code config directory to the mounted volume
ENV CLAUDE_CLI_CONFIG_DIR=${CLAUDE_CONFIG_DIR}

# Copy and set entrypoint script
COPY --chown=${UID}:${GID} entrypoint.sh ${HOME}/entrypoint.sh
RUN chmod +x ${HOME}/entrypoint.sh

# Copy run-claude helper
COPY --chown=${UID}:${GID} run-claude.sh /usr/local/bin/run-claude
RUN chmod +x /usr/local/bin/run-claude

# Set entrypoint to run updates on container start
ENTRYPOINT ["/home/anticlaude/entrypoint.sh"]

# Install Claude Code CLI
ARG CLAUDE_CACHEBUST=1
RUN curl -fsSL https://claude.ai/install.sh | /bin/bash

# Set working directory for projects
WORKDIR ${HOME}/workspace
