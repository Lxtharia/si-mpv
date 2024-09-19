#!/bin/bash

SOCKET="/tmp/mpv_socket"

# Ensure the file path is absolute
if [ -n "$1" ]; then
    FILE_PATH=$(realpath "$1")
else
    echo "Usage: $0 <file>"
    exit 1
fi

# Remove broken socket if necessary (timeout prevents waiting indefinitely)
if [ -S "$SOCKET" ]; then
    if ! echo '{ "command": ["get_property", "path"] }' | timeout 0.5 socat - "$SOCKET" >/dev/null 2>&1; then
        echo "Removing broken socket..."
        rm -f "$SOCKET"
    fi
fi

if [ -n "$1" ]; then
    if [ -S "$SOCKET" ]; then
        # Send file to existing mpv instance
        echo '{ "command": ["loadfile", "'"$1"'"] }' | socat - "$SOCKET"
    else
        # Start new mpv instance with IPC socket
        mpv --input-ipc-server="$SOCKET" "$1"
    fi
else
    echo "Usage: $0 <file>"
fi
