#!/bin/bash
set -euo pipefail

MARKER_FILE="$HOME/.anticlaude-initialized"

if [[ ! -f "$MARKER_FILE" ]]; then
    touch "$MARKER_FILE"
    exec claude --dangerously-skip-permissions "Install the necessary toolchains to work in this repository" "$@"
else
    exec claude --dangerously-skip-permissions "$@"
fi
