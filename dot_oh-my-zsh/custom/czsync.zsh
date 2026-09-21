# czsync must be a function, not an alias: the sync script runs as its own
# process, so anything it sources dies with it. Reloading has to happen here,
# in the interactive shell.
czsync() {
  ~/.local/share/chezmoi/.sync.sh "$@" || return

  local f
  for f in ~/.oh-my-zsh/custom/*.zsh(N); do
    source "$f" || print -u2 "czsync: failed to source $f"
  done

  # Several custom files prepend to PATH/MANPATH, so re-sourcing grows them.
  # Dedupe after the loop: an `export PATH=...` drops the -U flag, so setting it
  # beforehand leaves one stale duplicate behind.
  typeset -gU path fpath manpath
}
