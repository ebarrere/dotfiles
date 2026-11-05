# Glob python* so brew's Python bumps don't break the path.
for f in ${BREW_PREFIX:-/opt/homebrew}/opt/oci-cli/libexec/lib/python*/site-packages/oci_cli/bin/oci_autocomplete.sh(N); do source "$f"; done
