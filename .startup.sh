#!/bin/bash

set -ex

install_on_linux() {
    if which nix; then
        echo 'Nix is already installed'
    else
        sh <(curl -L https://nixos.org/nix/install) --daemon
    fi
    install_chezmoi
}

install_on_mac() {
    xcode-select --install || echo "XCode already installed"
    install_brew
    (
        echo
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    ) >>$HOME/.bashrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
    install_chezmoi
}

install_brew() {
    if which brew; then
        echo 'Homebrew is already installed'
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_chezmoi() {
    if which chezmoi; then
        echo 'Chezmoi is already installed'
    else
        $CHEZMOI_INSTALL_COMMAND
    fi
}

OS="$(uname -s)"
case "${OS}" in
Linux*)
    CHEZMOI_INSTALL_COMMAND="nix-env -iA nixpkgs.chezmoi"
    install_on_linux
    ;;
Darwin*)
    CHEZMOI_INSTALL_COMMAND="brew install chezmoi"
    install_on_mac
    ;;
*)
    echo "Unsupported operating system: ${OS}"
    exit 1
    ;;
esac

chezmoi init https://github.com/ebarrere/dotfiles
chezmoi apply