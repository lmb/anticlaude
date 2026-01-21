#!/usr/bin/env bash

exec podman build --build-arg CLAUDE_CACHEBUST=$(date +%s) -t anticlaude .
