#!/usr/bin/env bash
set -euo pipefail

SRC="${BOOKMARKSYNC_DIR:-$(pwd)}/data/bookmarks.xbel"
DEST="${BOOKMARKSYNC_DIR:-$(pwd)}/backup"
LOG="${BOOKMARKSYNC_DIR:-$(pwd)}/backup.log"

mkdir -p "$DEST"
cd "$DEST"

if [ ! -d .git ]; then
    git init -q
    git config user.email "backup@localhost"
    git config user.name "bookmark-backup"
fi

# skip if source is missing or empty
if [ ! -s "$SRC" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: source missing or empty, skipping backup" >> "$LOG"
    exit 0
fi

cp "$SRC" "$DEST/bookmarks.xbel"

if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "Backup $(date '+%Y-%m-%d %H:%M:%S')"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - changes committed" >> "$LOG"
fi
