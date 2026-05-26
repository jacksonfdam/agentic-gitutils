#!/usr/bin/env bash
# install.sh — symlink each bin/git-* into ~/.local/bin so they're picked up
# by git as `git foo`. Idempotent.
#
# Override target dir:
#   INSTALL_DIR=/usr/local/bin ./install.sh
#
# After install it will (interactively):
#   * offer to add a discovery hint to ~/.claude/CLAUDE.md so AI agents see
#     these commands in every project
#   * check whether a newer version is available on origin
# Pass --yes to accept those automatically, --no-hint to skip the agent hint,
# --no-update-check to skip the update probe.
#
# Uninstall:
#   ./install.sh --uninstall

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${INSTALL_DIR:-$HOME/.local/bin}"
ACTION="install"
AUTO_YES=0
SKIP_HINT=0
SKIP_UPDATE=0

for arg in "$@"; do
  case "$arg" in
    --uninstall|uninstall) ACTION="uninstall" ;;
    --yes|-y)              AUTO_YES=1 ;;
    --no-hint)             SKIP_HINT=1 ;;
    --no-update-check)     SKIP_UPDATE=1 ;;
    -h|--help)
      sed -n '2,18p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

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
  # Also remove the agent hint so the uninstall is symmetric.
  if [[ -x "$HERE/bin/git-utils" ]]; then
    "$HERE/bin/git-utils" uninstall-agent-hint || true
  fi
}

confirm() {
  # confirm "<question>" -> returns 0 if user says yes (or --yes was given)
  if [[ "$AUTO_YES" == "1" ]]; then return 0; fi
  if [[ ! -t 0 ]]; then return 1; fi  # non-interactive: don't prompt
  printf '%s [y/N] ' "$1"
  read -r ans
  [[ "$ans" =~ ^[Yy] ]]
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

  # ---- agent hint ----
  if [[ "$SKIP_HINT" == "0" ]]; then
    echo
    if confirm "Add a discovery hint to ~/.claude/CLAUDE.md so AI agents recognize these commands in every project?"; then
      "$HERE/bin/git-utils" install-agent-hint
    else
      echo "skipped agent hint. (you can run \`git utils install-agent-hint\` later)"
    fi
  fi

  # ---- update check ----
  if [[ "$SKIP_UPDATE" == "0" ]]; then
    echo
    echo "checking for updates…"
    # --check exits 0 whether or not there are updates; failures are advisory.
    "$HERE/bin/git-utils" update --check || \
      echo "(update check skipped — see message above)"
  fi

  echo
  echo "done — git-utils v$(cat "$HERE/VERSION" 2>/dev/null || echo unknown) installed."
}

case "$ACTION" in
  uninstall) uninstall ;;
  install)   install ;;
esac
