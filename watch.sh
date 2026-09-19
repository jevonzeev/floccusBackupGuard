#!/usr/bin/env bash
SRC_DIR="${BOOKMARKSYNC_DIR:-$(pwd)}/data"
BACKUP="${BOOKMARKSYNC_DIR:-$(pwd)}/backup.sh"

while true; do
    inotifywait -e modify,close_write "$SRC_DIR/bookmarks.xbel"
    sleep 5   # debounce
    "$BACKUP"
done
