#!/bin/bash
set -euo pipefail

agent="$1"
shift

case "$agent" in
    claude) agent_flags="--dangerously-skip-permissions" ;;
    codex)  agent_flags="--full-auto" ;;
    *)      echo "Error: unknown agent '$agent'" >&2; exit 1 ;;
esac

MARKER_FILE="$HOME/.anticlaude-initialized"

if [[ ! -f "$MARKER_FILE" ]]; then
    touch "$MARKER_FILE"
    exec "$agent" $agent_flags "Install the necessary toolchains to work in this repository" "$@"
else
    exec "$agent" $agent_flags "$@"
fi
