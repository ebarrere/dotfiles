# gwtclean: remove worktrees whose work is fully landed. Dry-run by default;
# pass -f to actually remove. Never touches the main worktree or the current one.
#
# "Landed" means merged into the default branch, tested two ways: a plain
# ancestor check, and -- because GitHub squash-merges rewrite history -- a
# patch-id check of the branch's tree replayed onto the merge base (the same
# trick omz's gbds uses). A squash-merged branch is not an ancestor of main.
gwtclean() {
  local force=0
  [[ "$1" == (-f|--force) ]] && force=1

  git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "gwtclean: not a git repository"; return 1 }

  local base main_wt cur_wt
  base=$(git_main_branch 2>/dev/null) || base=main
  main_wt=$(git worktree list --porcelain | awk '/^worktree /{print substr($0,10); exit}')
  cur_wt=$(git rev-parse --show-toplevel 2>/dev/null)

  local wt br keep n=0
  while IFS= read -r wt; do
    [[ -n "$wt" ]] || continue
    [[ "$wt" == "$main_wt" ]] && continue
    if [[ "$wt" == "$cur_wt" ]]; then print "  - ${wt:t} (current worktree)"; continue; fi

    br=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null)
    keep=""
    if [[ -z "$br" ]]; then
      keep="detached HEAD"
    elif [[ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]]; then
      keep="uncommitted changes"
    elif ! git merge-base --is-ancestor "$br" "$base" 2>/dev/null &&
         [[ $(git cherry "$base" \
                $(git commit-tree $(git rev-parse "$br^{tree}") \
                    -p $(git merge-base "$base" "$br") -m _) 2>/dev/null) != -* ]]; then
      keep="unmerged commits"
    fi

    if [[ -n "$keep" ]]; then
      print "  - ${wt:t} [$br] ($keep)"
      continue
    fi

    (( n++ ))
    if (( force )); then
      git worktree remove "$wt" && git branch -D "$br" >/dev/null 2>&1
      print "  ✓ removed ${wt:t} [$br]"
    else
      print "  would remove: ${wt:t} [$br]"
    fi
  done < <(git worktree list --porcelain | awk '/^worktree /{print substr($0,10)}')

  (( force )) || (( n == 0 )) && return 0
  print "\n  $n to remove; rerun as: gwtclean -f"
}
