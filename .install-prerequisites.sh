#!/bin/bash
# set -ex

if !type keeper &>/dev/null || !type bw &>/dev/null; then
    case "$(uname -s)" in
    Darwin)
        brew install keeper-commander
        brew install bitwarden-cli
        ;;
    Linux)
        nix-env -iA nixpkgs.keeper-commander
        nix-env -iA nixpkgs.bitwarden-cli
        ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
    esac
fi