#!/usr/bin/env zsh

function dc_exec {
  local command="$@"

  for dc in 1 2; do ssh root@dc${dc}.idm.orionspace.com "${command}" 2>/dev/null; done
}
