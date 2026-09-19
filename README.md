# floccus backup guard

An event driven backup pipeline that protects browser bookmarks synced via
[floccus](https://floccus.org/) against silent data loss from bad syncs.

## The problem

Bookmarks can represent hours of real organising work: saved study courses,
references, and links built up over a long time. floccus syncs bookmarks
between browsers through a remote store (WebDAV in this setup). If one
browser's local bookmarks are empty or corrupted and floccus treats that as
the source of truth, it can silently overwrite the shared remote copy, and
from there wipe every other synced browser too. Rebuilding that from
scratch is slow and often impossible to do perfectly.

## Architecture

```
Browser (floccus extension)
    WebDAV (Docker, bytemark/webdav)
    bind mounted bookmarks.xbel on host
    watched by inotify
    backup.sh copies and commits to a local git repo
```

Every change to the live bookmarks file is detected within seconds and
snapshotted into a git repository. This gives full version history and
point in time recovery.

## Setup

1. Copy `docker-compose.yml`, fill in your own `USERNAME` and `PASSWORD`,
   and run:
   ```bash
   docker compose up -d
   ```

2. Install `inotify-tools`:
   ```bash
   sudo apt install inotify-tools
   ```

3. Set the `BOOKMARKSYNC_DIR` environment variable to wherever this project
   lives (it defaults to the current directory if unset). 

   Run `watch.sh` as a persistent process. A systemd user service is recommended, so it
   survives reboots and restarts automatically:
   ```ini
   [Unit]
   Description=Watch and backup floccus bookmarks.xbel

   [Service]
   ExecStart=/path/to/floccus-backup-guard/watch.sh
   Restart=always

   [Install]
   WantedBy=default.target
   ```

4. Optional, but recommended: add a cron fallback in case the watcher
   process ever dies silently.
   ```
 */15 * * * * /path/to/floccus-backup-guard/backup.sh
   ```

## Checking on it

Confirm the service is alive:
```bash
systemctl --user status bookmark-backup.service
```
Look for `Active: active (running)`.

See recent backup activity:
```bash
tail -20 backup.log
```

See the full backup history:
```bash
cd backup
git log --oneline
```

## Recovering from a bad sync

1. Find the last good backup:
   ```bash
   cd backup
   git log --oneline
   ```

2. Restore it into the live WebDAV location:
   ```bash
   git show <good_commit_hash>:bookmarks.xbel > ../data/bookmarks.xbel
   ```

3. Let floccus sync down that restored file on each browser.

## Root cause reminder

A backup protects you and a sync i not a backup

## License

MIT, see LICENSE

