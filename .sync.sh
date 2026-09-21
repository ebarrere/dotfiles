#!/bin/sh
# czsync: reconcile this machine with the chezmoi repo.
#   externals  -> upstream always wins, they are never edited here
#   one-sided  -> captured or applied without asking
#   divergent  -> handed straight to `chezmoi merge`
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
MERGE="$(mktemp)"
CAPTURE="$(mktemp)"
trap 'rm -f "$PENDING" "$PULLED" "$MERGE" "$CAPTURE"' EXIT

# Commit last converged by a successful run. Lives in .git, so it is per-machine
# and never committed. Divergence is measured from here, not from this run's
# pull -- otherwise a rerun sees an empty pull and silently picks a side.
GITDIR="$(git -C "$SRC" rev-parse --git-dir)"
case "$GITDIR" in /*) ;; *) GITDIR="$SRC/$GITDIR" ;; esac
MARK="$GITDIR/czsync-last-applied"

# Column 1 of `chezmoi status` is M just when the *target* was modified.
locally_modified() {
  chezmoi status --exclude=externals --path-style=absolute \
    | awk '/^M/ { print substr($0, 4) }' > "$PENDING"
}

BEFORE="$(git -C "$SRC" rev-parse HEAD)"
git -C "$SRC" pull --rebase --autostash --prune -q
NOW="$(git -C "$SRC" rev-parse HEAD)"

BASE="$(cat "$MARK" 2>/dev/null || echo "")"
if [ -z "$BASE" ] || ! git -C "$SRC" cat-file -e "$BASE^{commit}" 2>/dev/null; then
  BASE="$BEFORE"
fi

# Externals are upstream's, never ours: take their version wholesale. Scoped by
# entry type, so files we layer inside an external tree (custom/*.zsh) are left
# alone -- only the archive's own content is reset.
chezmoi apply --force --refresh-externals --include=externals

git -C "$SRC" diff --name-only "$BASE" "$NOW" > "$PULLED"
locally_modified
: > "$MERGE"; : > "$CAPTURE"

# Split the locally-modified files. A file needs human eyes when the source also
# moved since we last converged (picking a side would silently revert one), or
# when it is template-backed (re-add refuses templates, so the edit is otherwise
# dropped and then overwritten by apply). Everything else is unambiguous.
while IFS= read -r target; do
  [ -n "$target" ] || continue
  sp="$(chezmoi source-path "$target" 2>/dev/null)" || continue
  case "$sp" in
    "$SRC"/*) rel="${sp#"$SRC"/}" ;;
    *) continue ;;
  esac
  if [ "$BASE" != "$NOW" ] && grep -qxF "$rel" "$PULLED"; then
    printf '%s\n' "$target" >> "$MERGE"
  elif [ "${rel%.tmpl}" != "$rel" ]; then
    printf '%s\n' "$target" >> "$MERGE"
  else
    printf '%s\n' "$target" >> "$CAPTURE"
  fi
done < "$PENDING"

if [ -s "$CAPTURE" ]; then
  tr '\n' '\0' < "$CAPTURE" | xargs -0 chezmoi re-add --
fi

if [ -s "$MERGE" ]; then
  echo "czsync: these changed on both sides, or are template-backed:" >&2
  sed 's/^/  /' "$MERGE" >&2
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    chezmoi merge "$target"
  done < "$MERGE"
fi

git -C "$SRC" add -A
git -C "$SRC" diff --cached --quiet \
  || git -C "$SRC" commit -qm "sync $(hostname -s) $(date +%F_%T)"
git -C "$SRC" push -q

chezmoi apply --force
git -C "$SRC" rev-parse HEAD > "$MARK"
