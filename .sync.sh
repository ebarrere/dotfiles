#!/bin/sh
set -eu
SRC="$(chezmoi source-path)"
chezmoi managed --include=files --exclude=externals --path-style=absolute \
  | tr '\n' '\0' | xargs -0 chezmoi re-add --          # capture edits + future files
git -C "$SRC" add -A
git -C "$SRC" diff --cached --quiet || git -C "$SRC" commit -qm "sync $(hostname -s) $(date +%F_%T)"
git -C "$SRC" pull --rebase -q && git -C "$SRC" push -q
BW_MASTER="$(security find-generic-password -s chezmoi-bw -w)"                    # master pw from Keychain
export BW_SESSION="$(printf '%s' "$BW_MASTER" | bw unlock --raw --passwordfile /dev/stdin)"
unset BW_MASTER
chezmoi apply --force
