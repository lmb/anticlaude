# Anticlaude - AI Coding Agents in a Lima VM

A wrapper that runs AI coding agents (Claude Code, Codex) inside a [Lima](https://lima-vm.io/) VM, isolating agent execution from your host system while giving you a consistent, reproducible environment.

## Overview

Anticlaude is a thin shim around `limactl shell` that:
- Supports multiple agents: **Claude Code** (`anticlaude`) and **Codex** (`anticodex`)
- Runs each agent inside a shared Lima VM named `default`
- Preserves your current working directory inside the VM (`limactl shell --workdir`)
- Passes the appropriate "skip permissions" flag for each agent automatically
- Refuses to run inside `$STARDIR` (or any subdirectory) as a safety check

## Prerequisites

- [Lima](https://lima-vm.io/) installed on your system, with a running instance named `default`
- An Anthropic API key for Claude Code (configured on first run)
- An OpenAI API key for Codex (optional, only needed if using Codex)
- The agent CLIs (`claude`, `codex`) installed inside the Lima VM and available on `PATH`

### Creating the Lima VM

If you don't already have a `default` Lima instance, create one:

```bash
limactl start default
```

Then install the agent CLIs inside the VM (e.g. via `limactl shell default`) so that `claude` and `codex` are on the VM's `PATH`.

## Installation

Symlink the `anticlaude` script onto your `PATH` and create the `anticodex` alias:

```bash
ln -s "$(pwd)/anticlaude" ~/.local/bin/anticlaude
ln -s "$(pwd)/anticlaude" ~/.local/bin/anticodex
```

The agent to launch is inferred from the invocation name (`anticlaude` → `claude`, `anticodex` → `codex`).

## Running an Agent

From any directory on the host:

```bash
anticlaude   # launches Claude Code with --dangerously-skip-permissions
anticodex    # launches Codex with --dangerously-bypass-approvals-and-sandbox
```

Any additional arguments are forwarded to the underlying agent.

### Working Directory

The script invokes `limactl shell --workdir "$(pwd)" default ...`, so the agent starts in the same path inside the VM as on the host. By default Lima mounts your home directory into the VM, which means most working directories Just Work; if your project lives outside the default mounts, configure additional mounts in your Lima instance's `lima.yaml`.

### STARDIR Guard

If the `STARDIR` environment variable is set and your current directory is inside it, the script refuses to start. This prevents launching an agent in a directory it shouldn't touch.

## Configuration

Agent configuration (API keys, settings) lives inside the Lima VM under the agent's usual paths (`~/.claude`, `~/.codex` for the VM user). Because the VM is persistent, configuration survives across sessions.

## Troubleshooting

### `limactl: command not found`
Install Lima and ensure it's on your `PATH`.

### `instance "default" does not exist` or stopped
Run `limactl start default` to create or start the VM.

### Agent not found inside the VM
Install the agent CLI inside the VM (`limactl shell default`, then install `claude` / `codex`) and confirm it's on the VM user's `PATH`.

### Files not visible inside the VM
Check the `mounts:` section of your Lima instance config and add the path your project lives in if it isn't already covered.
