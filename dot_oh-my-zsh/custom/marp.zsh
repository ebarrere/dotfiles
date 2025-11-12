marpp() {
  local input="$1"
  local output="${input%.md}.html"
  marp --no-stdin "$input" -o "$output" && open -a Arc "$output"
}