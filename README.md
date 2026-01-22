# Anticlaude - Containerized Claude Code CLI

A Podman container for running the Claude Code CLI in an isolated, reproducible environment. This container provides a consistent development experience across different systems while maintaining separation between your host system and Claude Code's dependencies.

## Overview

Anticlaude is a containerized version of Anthropic's Claude Code CLI that:
- Runs in an isolated Ubuntu-based environment
- Automatically updates Claude Code on container startup
- Preserves your Claude configuration across container restarts
- Creates persistent containers per working directory (installed packages survive sessions)
- Mounts your current working directory as the workspace
- Runs as a non-root user for security

## Prerequisites

- Podman installed on your system
- An Anthropic API key (will be configured on first run)
- Sufficient permissions to build containers and mount volumes

### NixOS

Add the following to configuration.nix to enable podman:

```
  # Enable Podman for container management
  virtualisation.podman = {
    enable = true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;
  };

  # Configure container registries
  virtualisation.containers.registries.search = [
    "docker.io"
    "quay.io"
    "ghcr.io"
  ];

  # Optional: Add your user to the podman group for rootless containers
  users.users.$USER = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "podman" ]; # added "podman"
  };
```

## Building the Container

Build the container image from the repo root:

```bash
./build.sh
```

Re-run the command to update your version of claude.

The build process will:
1. Start from the latest Ubuntu base image
2. Install required dependencies (curl, ca-certificates, git, python3)
3. Create a non-root user `anticlaude` with UID/GID 1000
4. Install the Claude Code CLI

## Running the Container

### Quick Start

Copy the `anticlaude` script to your PATH:

```bash
ln -s "$(pwd)/anticlaude" ~/.local/bin/anticlaude
```

Then run Claude Code from any directory:

```bash
anticlaude
```

### First Run

On first run, Claude Code will prompt you to configure your API key. The configuration will be persisted in `$HOME/.claude` on your host system.

### Container Persistence

The `anticlaude` script creates persistent containers named after your working directory:

| Working Directory | Container Name |
|-------------------|----------------|
| `~/dev/foo` | `anticlaude-dev-foo` |
| `~/projects/bar` | `anticlaude-projects-bar` |
| `/tmp/test` | `anticlaude-tmp-test` |
| `~/` | `anticlaude-home` |

This means packages installed inside a container persist across sessions for that directory.

### Managing Containers

List anticlaude containers:

```bash
podman ps -a --filter "name=anticlaude-"
```

Remove a specific container:

```bash
podman rm anticlaude-dev-foo
```

### Ephemeral Mode

If you prefer ephemeral containers that are removed on exit, use this alias instead:

```bash
alias anticlaude="podman run --userns=keep-id -it --rm -v \$HOME/.claude:/home/anticlaude/.claude:z -v \$(pwd):\$(pwd):z -w \$(pwd) anticlaude:latest"
```

## Volume Mounts

The container uses two volume mounts:

### 1. Configuration Directory
- **Host Path**: `$HOME/.claude`
- **Container Path**: `/home/anticlaude/.claude`
- **Purpose**: Stores Claude Code configuration, including API keys and settings
- **Persistence**: Data persists across container restarts

### 2. Workspace Directory
- **Host Path**: `$(pwd)` (current working directory)
- **Container Path**: `$(pwd)` (same as host path)
- **Purpose**: Your project files that Claude Code will operate on
- **Persistence**: Changes are reflected immediately on the host filesystem
- **Note**: The container uses `-w $(pwd)` to set the working directory to match the host path, enabling Claude to categorize conversations by project path

## Configuration Assumptions

### User ID/Group ID
- The container creates a user `anticlaude` with UID 1000 and GID 1000
- This matches the default user ID on most Linux systems
- If your host user has a different UID/GID, you may encounter permission issues with mounted volumes

### SELinux Considerations
- The `:z` suffix on volume mounts enables SELinux relabeling
- This allows the container to access mounted volumes on SELinux-enabled systems (Fedora, RHEL, CentOS, etc.)

### User Namespace Mapping
- The `--userns=keep-id` flag preserves your host user ID inside the container
- This ensures files created in mounted volumes have the correct ownership

## Limitations

### UID/GID Mismatch
If your host user ID is not 1000, you may need to:
- Rebuild the container with your specific UID/GID in the Dockerfile
- Use rootless Podman with user namespace mapping
- Adjust file permissions manually

### Network Access
The container requires internet access to:
- Install Claude Code during the build
- Update Claude Code on startup
- Communicate with Anthropic's API during operation

### Automatic Updates
- The entrypoint script automatically runs `claude update` on container startup
- This ensures you're always running the latest version
- Initial startup may take a few seconds while updates are checked/applied
- If you want to skip updates, you would need to modify the entrypoint script

### Host System Integration
- The container runs in isolation and doesn't have direct access to host system services
- Host GUI applications cannot be launched from within the container
- System-level tools on the host are not available inside the container

### Container Persistence
- The `anticlaude` script creates persistent containers per working directory
- Packages installed inside a container persist across sessions
- Use the ephemeral mode alias if you prefer containers that are removed on exit
- Container data is stored in Podman's default location

## Troubleshooting

### Permission Denied Errors
If you encounter permission errors with volume mounts:
- Check that `$HOME/.claude` exists and is writable
- Verify your user ID matches the container's UID (1000)
- On SELinux systems, ensure the `:z` flag is used with Podman

### API Key Issues
If Claude Code can't find your API key:
- Ensure the config volume is properly mounted
- Check that `$HOME/.claude` contains your configuration
- Try running `claude configure` inside the container

### Update Failures
If the entrypoint update fails:
- Check your internet connection
- Verify you can access `https://claude.ai`
- The entrypoint script will attempt to recover by running `claude install` first
