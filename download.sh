#!/bin/bash

clear

while true; do
    echo
    if [ -n "$1" ]; then
        URL="$1"
        shift
    else
        read -p "Enter YouTube URL (or press Enter to quit): " URL
    fi

    if [ -z "$URL" ]; then
        break
    fi

    echo
    echo "Downloading highest quality video..."
    echo

    yt-dlp \
        -f "bv*+ba/b" \
        --merge-output-format mp4 \
        --embed-metadata \
        --embed-thumbnail \
        --add-metadata \
        -o "$HOME/Downloads/%(title)s.%(ext)s" \
        "$URL"

    echo
    echo "Finished."
done

echo
echo "Download complete."       