# Troubleshooting

## Why the recovery command needs `sudo sh -c '...'`

Shell redirection is resolved by the shell parsing the command line, not
by the command being run. In:

```bash
sudo git show <hash>:bookmarks.xbel > /path/to/data/bookmarks.xbel
```

your own unprivileged shell opens the destination file for writing before
`sudo` takes effect. `sudo` only elevates `git show`, not the write.
Since the live file is owned by uid 82, the WebDAV container's user
inside the Docker image, that write fails with a permission error before
anything is restored.

Wrapping the whole line in `sudo sh -c '...'` runs a new shell as root,
so the redirection itself happens under root and the write succeeds:

```bash
sudo sh -c 'git show <hash>:bookmarks.xbel > /path/to/data/bookmarks.xbel'
```

## Why E030 can mean two different things

Floccus encrypts the WebDAV file client side, using a key derived from
the profile's passphrase, with an authenticated cipher. On sync it
decrypts and verifies that authentication tag. `E030` is the one generic
error Floccus reports whenever that check fails, and it covers two
different causes that look identical from the outside:

* a truncated or corrupted ciphertext
* a correct ciphertext being decrypted with the wrong key

An authentication tag check cannot distinguish these, so the error
message alone does not tell you which one you are facing.

Check the file's integrity directly, independent of floccus:

```bash
stat /path/to/data/bookmarks.xbel
```

A size of `0` means the file was truncated at the filesystem level, most
likely by an interrupted write, confirming corruption as the cause.

If the size looks like a normal encrypted file and it still fails, the
ciphertext is intact and the cause is almost always a passphrase
mismatch, the passphrase currently entered in the floccus profile no
longer matches the one that encrypted this file.

The reliable fix in either case is the same: delete the undecryptable
file and let floccus regenerate it fresh from a known good local state,
rather than trying to recover the old passphrase.

```bash
curl -u <username> -X DELETE http://localhost:8085/bookmarks.xbel
```

Then sync from a browser with good bookmarks. Floccus creates a new file
encrypted with whichever passphrase is currently entered in that profile.
Every device syncing to this WebDAV target from then on must use that
exact same passphrase.
