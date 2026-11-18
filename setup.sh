#!/bin/bash
# setup.sh - create symlinks for dotfiles

set -e

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# bash
ln -sf "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"

# Worktrunk
bash "$DOTFILES_DIR/bash/setup-worktrunk.sh"

# Zsh
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# opencode
ln -sf "$DOTFILES_DIR/opencode" "$HOME/.config/opencode"

# opencode
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

echo "Symlinks created successfully!"
