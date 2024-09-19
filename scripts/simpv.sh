#!/bin/bash

# Default socket path
SOCKET="/tmp/mpv_socket"

# Ensure a file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [--replace|--append-play|--append] --socket <path> <file> [mpv_options]"
    exit 1
fi

# Parse options
ACTION="replace"  # Default action is to replace the file
MPV_OPTIONS=()    # Array to store mpv options for the first instance
FILE_PATH=""
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
        -*)
            # If the argument starts with `-` but isn't one of our options, it's an mpv option
            MPV_OPTIONS+=("$1")
            shift
            ;;
        *)
            if [[ -z "$FILE_PATH" ]]; then
                # Make sure to use the full path
                FILE_PATH=$(realpath "$1")  # First non-option argument is the file
            else
                echo "Error: Unexpected argument before file: $1"
                exit 1
            fi
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
    echo "Error: Not a valid file."
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
    # Start new mpv instance with IPC socket and provided mpv options
    mpv --input-ipc-server="$SOCKET" "${MPV_OPTIONS[@]}" "$FILE_PATH"
fi
