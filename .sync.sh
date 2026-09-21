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

PENDING="$(mktemp)"
PULLED="$(mktemp)"
CLASH="$(mktemp)"
trap 'rm -f "$PENDING" "$PULLED" "$CLASH"' EXIT

# Commit last converged by a successful run. Lives in .git, so it is per-machine
# and never committed. The clash check below measures from here, not from this
# run's pull -- otherwise a rerun after an abort sees an empty pull and clobbers.
GITDIR="$(git -C "$SRC" rev-parse --git-dir)"
case "$GITDIR" in /*) ;; *) GITDIR="$SRC/$GITDIR" ;; esac
MARK="$GITDIR/czsync-last-applied"

# Column 1 of `chezmoi status` is M just when the *target* was modified; " M"
# means the source is ahead, and re-adding those reverts them (this is what kept
# eating custom/brew.zsh). Externals are the upstream omz archive, never ours.
locally_modified() {
  chezmoi status --exclude=externals --path-style=absolute \
    | awk '/^M/ { print substr($0, 4) }' > "$PENDING"
}

# Incoming changes first, so the re-add below cannot revert another host's work.
BEFORE="$(git -C "$SRC" rev-parse HEAD)"
git -C "$SRC" pull --rebase --autostash -q
NOW="$(git -C "$SRC" rev-parse HEAD)"

BASE="$(cat "$MARK" 2>/dev/null || echo "")"
if [ -z "$BASE" ] || ! git -C "$SRC" cat-file -e "$BASE^{commit}" 2>/dev/null; then
  BASE="$BEFORE"
fi

locally_modified

# Fail closed when a file changed both here and upstream. git cannot catch this:
# the local edit lives in the target, outside the repo, so the pull fast-forwards
# cleanly and re-add would overwrite the incoming version with no warning.
if [ "${CZSYNC_RESOLVED:-0}" != "1" ] && [ "$BASE" != "$NOW" ] && [ -s "$PENDING" ]; then
  git -C "$SRC" diff --name-only "$BASE" "$NOW" > "$PULLED"
  : > "$CLASH"
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    sp="$(chezmoi source-path "$target" 2>/dev/null)" || continue
    case "$sp" in
      "$SRC"/*) rel="${sp#"$SRC"/}" ;;
      *) continue ;;
    esac
    if grep -qxF "$rel" "$PULLED"; then printf '%s\n' "$target" >> "$CLASH"; fi
  done < "$PENDING"
  if [ -s "$CLASH" ]; then
    echo "czsync: changed both here and upstream, refusing to overwrite:" >&2
    sed 's/^/  /' "$CLASH" >&2
    echo "czsync: merge each with 'chezmoi merge <file>', then rerun as:" >&2
    echo "czsync:   CZSYNC_RESOLVED=1 czsync" >&2
    echo "czsync: nothing was committed or pushed." >&2
    exit 1
  fi
fi

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
git -C "$SRC" rev-parse HEAD > "$MARK"
