#!/bin/bash
set -ex

if type keeper >/dev/null 2>&1; then
    echo "Keeper cli is already installed"
else
    case "$(uname -s)" in
    Darwin)
        brew install keeper-commander
        ;;
    # Linux)
    #     nix-env -iA nixpkgs.keeper-commander
    #     ;;
    *)
        echo "unsupported OS"
        exit 1
        ;;
    esac
fi