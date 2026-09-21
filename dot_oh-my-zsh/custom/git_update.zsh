# gup: fetch + prune every remote, then fast-forward every local branch that
# tracks one. Only ever fast-forwards -- diverged branches are reported, never
# rewritten. Pairs with omz's gbgd, which deletes branches whose upstream is gone.
gup() {
  git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "gup: not a git repository"; return 1 }
  git fetch --all --prune --prune-tags --tags --jobs=10 || return 1

  local cur ref up track gone=()
  cur=$(git symbolic-ref --quiet --short HEAD)

  while read -r ref up track; do
    if [[ -z $up ]]; then
      print "  - $ref (no upstream)"
    elif [[ $track == '[gone]' ]]; then
      print "  ✗ $ref (upstream gone)"; gone+=($ref)
    elif [[ $ref == "$cur" ]]; then
      git merge --ff-only "$up" >/dev/null 2>&1 \
        && print "  ✓ $ref" || print "  ! $ref (checked out, needs manual merge/rebase)"
    else
      git fetch --quiet . "$up:$ref" 2>/dev/null \
        && print "  ✓ $ref" || print "  ! $ref (diverged, skipped)"
    fi
  done < <(git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads)

  (( $#gone )) && print "\n  ${#gone} with gone upstream; delete merged ones with: gbgd"
  return 0
}
