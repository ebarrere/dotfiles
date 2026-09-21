#!/bin/sh
# czsync: capture local edits into the chezmoi repo, push, then converge the target.
# Deliberately no `set -x`: tracing would print the Bitwarden master password.
set -eu

SRC="$(chezmoi source-path)"

# Unlock Bitwarden first. custom/private_sensitive.zsh.tmpl calls `bw`, so every
# chezmoi command that renders templates (status, diff, apply) fails with
# "You are not logged in" until BW_SESSION is set.
BW_SESSION="$(security find-generic-password -s chezmoi-bw -w \
  | bw unlock --raw --passwordfile /dev/stdin)"
export BW_SESSION

# Incoming changes first, so the re-add below cannot revert another host's work.
git -C "$SRC" pull --rebase --autostash -q

PENDING="$(mktemp)"
trap 'rm -f "$PENDING"' EXIT
locally_modified() {
  chezmoi status --exclude=externals --path-style=absolute \
    | awk '/^M/ { print substr($0, 4) }' > "$PENDING"
}

# Capture local edits only. Column 1 of `chezmoi status` is M just when the
# *target* was modified; " M" means the source is ahead, and re-adding those
# reverts them (this is what kept eating custom/brew.zsh). Externals are the
# upstream omz archive, never ours to commit.
locally_modified
if [ -s "$PENDING" ]; then
  tr '\n' '\0' < "$PENDING" | xargs -0 chezmoi re-add --
fi

git -C "$SRC" add -A
git -C "$SRC" diff --cached --quiet \
  || git -C "$SRC" commit -qm "sync $(hostname -s) $(date +%F_%T)"
git -C "$SRC" push -q

# re-add refuses to write templates, so anything still flagged here is backed by
# a .tmpl and `apply --force` would silently destroy the local edit. Stop instead.
locally_modified
if [ -s "$PENDING" ]; then
  echo "czsync: pushed, but these template-backed edits could not be captured:" >&2
  sed 's/^/  /' "$PENDING" >&2
  echo "czsync: hand-merge with 'chezmoi merge <file>', then rerun. Skipping apply." >&2
  exit 1
fi

chezmoi apply --force
