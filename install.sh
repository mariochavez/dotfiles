#!/usr/bin/env bash
# install.sh — set up these dotfiles on macOS or Omarchy (Arch + Hyprland).
#
#   ./install.sh              install packages, then stow everything
#   ./install.sh --stow-only  skip package installation
#   ./install.sh --packages   only install packages
#   ./install.sh --dry-run    show what would happen, change nothing
#
# Existing real files at a stow target are moved to ~/.dotfiles-backup/<stamp>/
# rather than deleted. `stow --adopt` is deliberately NOT used: it would pull
# the machine's current config *into* this repo and overwrite what's tracked.
set -euo pipefail

cd "$(dirname "$0")"
REPO="$PWD"

STOW_PACKAGES=(bat bin ghostty herdr kitty mise nvim pi starship tmux yazi zsh)

DO_PACKAGES=1
DO_STOW=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --stow-only) DO_PACKAGES=0 ;;
    --packages)  DO_STOW=0 ;;
    --dry-run)   DRY_RUN=1 ;;
    -h|--help)   sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then echo "  would run: $*"; else "$@"; fi; }

########## PLATFORM ##########

case "$OSTYPE" in
  darwin*) OS=macos ;;
  linux*)  OS=linux ;;
  *) echo "unsupported platform: $OSTYPE" >&2; exit 1 ;;
esac

IS_OMARCHY=0
[ "$OS" = linux ] && [ -d /usr/share/omarchy ] && IS_OMARCHY=1

say "Platform: $OS$([ "$IS_OMARCHY" -eq 1 ] && echo ' (Omarchy)')"

# Platform-only packages. `bin-linux` holds the pbcopy/pbpaste shims, which
# exist purely to supply names macOS already provides natively — stowing them
# there would shadow the real binaries.
if [ "$OS" = linux ]; then
  STOW_PACKAGES+=(bin-linux)
fi

########## PACKAGES ##########

install_macos_packages() {
  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew not found — install it from https://brew.sh first"
    return 1
  fi

  run brew install \
    git lazygit ghostty starship fzf fd eza bat zoxide neovim tmux yazi \
    zsh-autosuggestions zsh-syntax-highlighting stow font-meslo-lg-nerd-font
}

install_arch_packages() {
  # Omarchy already ships most of this; pacman skips what is present. The three
  # that a stock Omarchy install is missing are the two zsh plugins and the
  # Meslo Nerd Font this config asks for.
  local packages=(
    git lazygit ghostty starship fzf fd eza bat zoxide neovim tmux yazi stow
    zsh zsh-autosuggestions zsh-syntax-highlighting ttf-meslo-nerd wl-clipboard
  )

  if [ "$IS_OMARCHY" -eq 1 ] && command -v omarchy >/dev/null 2>&1; then
    run omarchy pkg add "${packages[@]}"
  else
    run sudo pacman -S --needed "${packages[@]}"
  fi
}

if [ "$DO_PACKAGES" -eq 1 ]; then
  say "Installing packages"
  if [ "$OS" = macos ]; then
    install_macos_packages
  elif [ -f /etc/arch-release ] || [ "$IS_OMARCHY" -eq 1 ]; then
    install_arch_packages
  else
    warn "Not macOS or Arch — install the tools listed in README.md by hand"
  fi

  # herdr has its own installer on every platform.
  if ! command -v herdr >/dev/null 2>&1; then
    say "herdr is not installed: curl -fsSL https://herdr.dev/install.sh | sh"
  fi
fi

########## STOW ##########

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Move any real file sitting at a stow target out of the way. On Omarchy this
# is what clears ~/.config/ghostty/config and friends, which the distro ships
# as regular files.
backup_conflicts() {
  local pkg="$1" src rel target moved=0

  while IFS= read -r src; do
    rel="${src#"$pkg"/}"
    target="$HOME/$rel"

    [ -e "$target" ] || continue

    # Already stowed? `-ef` compares device+inode, so this is true both when
    # the file itself is the symlink and when stow folded a whole directory
    # (~/.config/nvim -> repo), where the files inside are not symlinks at all
    # and a plain -L test would wrongly report a conflict — and move the repo's
    # own files into the backup.
    [ "$target" -ef "$src" ] && continue

    # Some other symlink the user put there; leave it alone.
    [ -L "$target" ] && continue

    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  would back up: $target"
    else
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
    fi
    moved=1
    # The filters mirror stow's built-in ignore list. Without them a package
    # containing its own README.md would make this move an unrelated
    # ~/README.md aside, for a link stow is never going to create.
  done < <(find "$pkg" \( -type f -o -type l \) \
    ! -name 'README.*' ! -name 'LICENSE.*' ! -name 'COPYING' \
    ! -name '.gitignore' ! -name '.gitmodules' ! -name '.DS_Store')

  [ "$moved" -eq 1 ] && say "  backed up existing files from $pkg to $BACKUP_DIR"
  return 0
}

if [ "$DO_STOW" -eq 1 ]; then
  say "Stowing: ${STOW_PACKAGES[*]}"

  for pkg in "${STOW_PACKAGES[@]}"; do
    [ -d "$REPO/$pkg" ] || { warn "  skipping $pkg (no such directory)"; continue; }
    backup_conflicts "$pkg"
    run stow --target="$HOME" "$pkg"
  done

  say "Done. Restart your shell."

  if [ "$OS" = linux ] && [ "$SHELL" != "$(command -v zsh)" ]; then
    say "zsh is not your login shell yet: chsh -s \"$(command -v zsh)\""
  fi
fi
