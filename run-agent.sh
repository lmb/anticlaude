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

read -r -d '' instructions <<EOF || true
Install the necessary toolchains to work in this repository. Verify that they
are available in PATH by running them directly (e.g. cargo --version) — do not
source env files or modify PATH inline as part of verification. Create an empty
file at $MARKER_FILE once verified.
EOF

if [[ ! -f "$MARKER_FILE" ]]; then
    exec "$agent" $agent_flags "$instructions" "$@"
else
    exec "$agent" $agent_flags "$@"
fi
