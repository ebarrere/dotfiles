# Mark folders trusted in Claude Code (parent trust doesn't cover children). Run with no Claude session open.
claude-trust() {
  local cfg=~/.claude.json p
  for p in "${@:-$PWD}"; do
    p=${p:A}  # absolute path, symlinks resolved
    [[ -d $p ]] || { echo "not a dir: $p" >&2; continue; }
    jq --arg p "$p" '.projects[$p].hasTrustDialogAccepted = true' "$cfg" > "$cfg.tmp" && mv "$cfg.tmp" "$cfg"
    echo "trusted $p"
  done
}
