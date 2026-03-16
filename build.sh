#!/usr/bin/env bash

cd "$(dirname "$0")"

exec podman build --build-arg CLAUDE_CACHEBUST=$(date +%s) -t anticlaude:latest .
