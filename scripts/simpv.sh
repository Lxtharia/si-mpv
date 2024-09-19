#!/bin/bash

# Default socket path
SOCKET="/tmp/mpv_socket"

# Ensure a file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [--replace|--append-play|--append] --socket <path> <file> -- [mpv_options]"
    exit 1
fi

# Parse options
ACTION="replace" # Default action is to queue the file
MPV_OPTIONS=()
FILE_PATH=""
SEPARATOR_FOUND=0
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
        SEPARATOR_FOUND=1
        shift
        break
    fi
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
            if [[ -z "$FILE_PATH" ]]; then
                # Make sure to use the full path
                FILE_PATH=$(realpath "$1")  # First non-option argument is the file
            else
                echo "Error: Unexpected argument before file or '--': $1"
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
    echo "Not a valid file"
    exit 1
fi

# After `--`, all remaining arguments are mpv options
if [[ $SEPARATOR_FOUND -eq 1 ]]; then
    MPV_OPTIONS=("$@")
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
    mpv --input-ipc-server="$SOCKET" "${MPV_OPTIONS[@]}" "$FILE_PATH"
fi

