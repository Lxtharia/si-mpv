#!/bin/bash

# Default socket path
SOCKET="/tmp/mpv_socket"

# Ensure a file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [--playnow|--playnext|--queue] --socket <path> <file>"
    exit 1
fi

# Parse options
ACTION="replace" # Default action is to queue the file
while [[ $# -gt 0 ]]; do
    case "$1" in
        --replace | --playnow)
            ACTION="replace"
            shift
            ;;
        --append-play)
            ACTION="appendplay"
            shift
            ;;
        --append | --queue)
            ACTION="append"
            shift
            ;;
        --socket)
            SOCKET="$2"
            shift 2
            ;;
        *)
            # Check if a file was provided
            if [ -z "$1" ]; then
                echo "Error: No file specified."
                exit 1
            fi
            # Make sure to use the full path
            FILE_PATH=$(realpath "$1")
            shift
            ;;
    esac
done


# Check if a file was provided
if [[ -z "$FILE_PATH" ]]; then
    echo "Error: No file specified."
    exit 1
fi

if ! [[ -f "$FILE_PATH" ]]; then
    echo "Not a valid file"
    exit 1
fi

# Remove broken socket if necessary (timeout prevents waiting indefinitely)
if [ -S "$SOCKET" ]; then
    if ! echo '{ "command": ["get_property", "path"] }' | timeout 0.5 socat - "$SOCKET" >/dev/null 2>&1; then
        echo "Removing broken socket..."
        rm -f "$SOCKET"
    fi
fi

# If socket exists, send the command to the running mpv instance
if [ -S "$SOCKET" ]; then
    case "$ACTION" in
        replace)
            echo '{ "command": ["loadfile", "'"$FILE_PATH"'", "replace"] }' | socat - "$SOCKET"
            ;;
        appendplay)
            echo '{ "command": ["loadfile", "'"$FILE_PATH"'", "append-play"] }' | socat - "$SOCKET"
            ;;
        append)
            echo '{ "command": ["loadfile", "'"$FILE_PATH"'", "append"] }' | socat - "$SOCKET"
            ;;
    esac
else
    # Start new mpv instance with IPC socket
    mpv --input-ipc-server="$SOCKET" "$FILE_PATH"
fi
