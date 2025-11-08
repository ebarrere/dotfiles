#!/bin/bash
# set -ex

missing_tools=()
! type keeper &>/dev/null && missing_tools+=("keeper")
! type bw &>/dev/null && missing_tools+=("bw")

if [ "${#missing_tools[@]}" -gt 0 ]; then
    case "$(uname -s)" in
    Darwin)
        if [[ " ${missing_tools[@]} " =~ " keeper " ]]; then
            brew install keeper-commander
        fi
        if [[ " ${missing_tools[@]} " =~ " bw " ]]; then
            brew install bitwarden-cli
        fi
        ;;
    Linux)
        if [[ " ${missing_tools[@]} " =~ " keeper " ]]; then
            nix-env -iA nixpkgs.keeper-commander
        fi
        if [[ " ${missing_tools[@]} " =~ " bw " ]]; then
            nix-env -iA nixpkgs.bitwarden-cli
        fi
        ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
    esac
fi