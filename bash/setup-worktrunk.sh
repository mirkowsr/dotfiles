#!/bin/bash

set -euo pipefail

if ! command -v wt >/dev/null 2>&1; then
  BREW="$(command -v brew 2>/dev/null || true)"
  if [ -z "$BREW" ] && [ -x /opt/homebrew/bin/brew ]; then
    BREW=/opt/homebrew/bin/brew
  fi
  if [ -z "$BREW" ] && [ -x /usr/local/bin/brew ]; then
    BREW=/usr/local/bin/brew
  fi

  if [ -z "$BREW" ]; then
    printf 'Worktrunk setup requires Homebrew when wt is not already installed.\n' >&2
    exit 1
  fi

  BREW_BIN_DIR="$(dirname "$BREW")"
  case ":$PATH:" in
    *":$BREW_BIN_DIR:"*) ;;
    *) export PATH="$BREW_BIN_DIR:$PATH" ;;
  esac

  "$BREW" install worktrunk
fi

if ! command -v wt >/dev/null 2>&1; then
  printf 'Worktrunk installation completed, but wt is not available in PATH.\n' >&2
  exit 1
fi

printf 'Worktrunk is installed. Shell integration is managed by the dotfiles shell configuration.\n'
