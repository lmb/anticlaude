#!/bin/bash
trap 'exit 0' SIGTERM SIGINT

while true; do
    sleep 60 & # background so that `wait` can be interrupted by signals
    wait $!
    session_count=$(ps ax -o pid,tty --no-headers | awk -v me=$$ '$1 != me && $2 ~ /pts/ { count++ } END { print count+0 }')
    if [ "$session_count" -eq 0 ]; then
        exit 0
    fi
done
