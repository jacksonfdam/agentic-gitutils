#!/usr/bin/env bash
# install.sh — symlink each bin/git-* into ~/.local/bin so they're picked up
# by git as `git foo`. Idempotent.
#
# Override target dir:
#   INSTALL_DIR=/usr/local/bin ./install.sh
#
# Uninstall:
#   ./install.sh --uninstall

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${INSTALL_DIR:-$HOME/.local/bin}"
ACTION="${1:-install}"

if [[ ! -d "$HERE/bin" ]]; then
  echo "error: $HERE/bin not found" >&2
  exit 1
fi

mkdir -p "$TARGET"

uninstall() {
  for src in "$HERE"/bin/git-*; do
    name="$(basename "$src")"
    link="$TARGET/$name"
    if [[ -L "$link" ]] && [[ "$(readlink "$link")" == "$src" ]]; then
      rm "$link"
      echo "removed $link"
    fi
  done
}

install() {
  for src in "$HERE"/bin/git-*; do
    name="$(basename "$src")"
    link="$TARGET/$name"
    if [[ -e "$link" && ! -L "$link" ]]; then
      echo "skip $link — exists and is not a symlink" >&2
      continue
    fi
    ln -sf "$src" "$link"
    echo "linked $link -> $src"
  done

  case ":$PATH:" in
    *":$TARGET:"*) ;;
    *) echo
       echo "note: $TARGET is not on your PATH. Add to your shell rc:"
       echo "      export PATH=\"$TARGET:\$PATH\""
       ;;
  esac
}

case "$ACTION" in
  --uninstall|uninstall) uninstall ;;
  *) install ;;
esac
