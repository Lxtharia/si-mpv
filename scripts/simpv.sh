#!/bin/bash

# Default socket path
SOCKET="/tmp/mpv_socket"

# Ensure at least one file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 [--replace|--append-play|--append] --socket <path> <file1> [<file2> ...] [mpv_options]"
    exit 1
fi

# Parse options
ACTION="replace"  # Default action is to replace the file
MPV_OPTIONS=()    # Array to store mpv options for the first instance
FILES=()          # Array to store file paths

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
            # Treat as a file, make sure to use the full path
            FILES+=("$(realpath "$1")")
            shift
            ;;
    esac
done

# Check if at least one file was provided
if [ ${#FILES[@]} -eq 0 ]; then
    echo "Error: No file specified."
    exit 1
fi

# Ensure all provided files exist
for FILE_PATH in "${FILES[@]}"; do
    if ! [[ -f "$FILE_PATH" ]]; then
        echo "Error: Not a valid file: $FILE_PATH"
        exit 1
    fi
done

# Remove broken socket if necessary (timeout prevents waiting indefinitely)
if [ -S "$SOCKET" ]; then
    if ! echo '{ "command": ["get_property", "path"] }' | timeout 0.5 socat - "$SOCKET" >/dev/null 2>&1; then
        echo "Removing broken socket..."
        rm -f "$SOCKET"
    fi
fi

# Function to send loadfile commands to a running mpv instance
send_to_mpv() {
    local action="$1"
    local file="$2"
    echo '{ "command": ["loadfile", "'"$file"'", "'"$action"'"] }' | socat - "$SOCKET"
}

# If socket exists, send the command to the running mpv instance
if [ -S "$SOCKET" ]; then
    case "$ACTION" in
        replace)
            send_to_mpv "replace" "${FILES[0]}"
            for i in "${FILES[@]:1}"; do
                send_to_mpv "append" "$i"
            done
            ;;
        appendplay)
            for file in "${FILES[@]}"; do
                send_to_mpv "append-play" "$file"
            done
            ;;
        append)
            for file in "${FILES[@]}"; do
                send_to_mpv "append" "$file"
            done
            ;;
    esac
else
    # Start a new mpv instance and queue all files with provided mpv options
    echo "Starting new mpv instance with options: ${MPV_OPTIONS[@]}"
    mpv --input-ipc-server="$SOCKET" "${MPV_OPTIONS[@]}" "${FILES[@]}"
fi
