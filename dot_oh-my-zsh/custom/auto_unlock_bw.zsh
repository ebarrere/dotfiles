command -v bw &>/dev/null || {
  echo >&2 "This script requires the bitwarden CLI but it's not installed.  Aborting."
  exit 1
}

rootDir="$(dirname "$(dirname "$0")")"
envFilePath="$rootDir/.env"
tmpFile="$rootDir/tmp.txt"

if [[ -f $envFilePath ]]; then
  set -o allexport
  . "$envFilePath"
  set +o allexport
fi

if [[ -z "$MASTER_PASSWORD" ]]; then
  if [[ $SHELL == "/bin/zsh" ]]; then
    read -sr "MASTER_PASSWORD?$(echo -e 'Bitwarden master password not set in .env, please provide it:\n> ')"
  elif [[ $SHELL == "/bin/bash" ]]; then
    read -srp "$(echo -e 'Bitwarden master password not set in .env, please provide it:\n> ')" MASTER_PASSWORD
  else
    echo "$SHELL is not supported"
    exit 1
  fi

  [[ -z "$MASTER_PASSWORD" ]] && echo "Script cannot run without bitwarden master password" && exit 1

  [[ ! -f "$envFilePath" ]] && touch "$envFilePath"
  echo "MASTER_PASSWORD=$MASTER_PASSWORD" >"$envFilePath"
fi

expect <(
  cat <<EOF
  spawn bw unlock
  expect "Master Password:"
  send "$MASTER_PASSWORD\r"
  interact
EOF
) 2>/dev/null 1>"$tmpFile"

sessionKey=$(grep -o '".*"' "$tmpFile" | sed 's/"//g' | uniq)
rm "$tmpFile"

if [[ -z $sessionKey ]]; then
  if [[ $SHELL == "/bin/zsh" ]]; then
    read -r "EMAIL?$(echo -e '\nPlease enter your Bitwarden account email address:\n> ')"
  elif [[ $SHELL == "/bin/bash" ]]; then
    read -rp "$(echo -e '\nPlease enter your Bitwarden account email address:\n> ')" EMAIL
  else
    echo "$SHELL is not supported"
    exit 1
  fi

  LOGIN_INFO=$(bw login "$EMAIL" "$MASTER_PASSWORD")
  sessionKey=$(echo "$LOGIN_INFO" | grep "BW_SESSION" | grep -oP '"\K[^"\047]+(?=["\047])' | uniq)
fi

export BW_SESSION="$sessionKey"
