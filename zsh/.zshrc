########## PLATFORM DETECTION ##########

# Everything OS-specific in this file keys off these flags. They are empty when
# false, so `[[ -n $IS_MACOS ]]` is the test to use.
typeset -g IS_MACOS="" IS_LINUX="" IS_OMARCHY=""

case "$OSTYPE" in
  darwin*) IS_MACOS=1 ;;
  linux*)  IS_LINUX=1 ;;
esac

# Omarchy (Arch + Hyprland). /usr/share/omarchy is owned by the omarchy
# package, so its presence is a cheap, fork-free distro check.
[[ -n $IS_LINUX && -d /usr/share/omarchy ]] && IS_OMARCHY=1

########## SHELL CONFIGURATION ##########

# Disable Ruby Warnings
export RUBYOPT="-W0"

# Config directory
export XDG_CONFIG_HOME="$HOME/.config"

# User configuration
export EDITOR="nvim"

# Bat theme
export BAT_THEME="Catppuccin Mocha"

# Disable Claude Code terminal flicker
export CLAUDE_CODE_NO_FLICKER=1

# History control
# Increase history size
HISTSIZE=1000000
SAVEHIST=2000000
HISTFILE=~/.zsh_history

# Share history between sessions
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# Avoid duplicate commands in history
setopt HIST_IGNORE_DUPS       # Ignore duplicate commands
setopt HIST_IGNORE_SPACE      # Ignore commands starting with a space
setopt HIST_SAVE_NO_DUPS      # Remove duplicates when saving history
setopt HIST_REDUCE_BLANKS     # Remove unnecessary blanks

########## PATH ##########

# Shared entries, highest priority first.
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$PATH"

if [[ -n $IS_MACOS ]]; then
  # Add Homebrew to path. Prefer a per-user install in ~/homebrew (used when
  # /opt/homebrew belongs to another account on a shared Mac).
  if [[ -x $HOME/homebrew/bin/brew ]]; then
    eval "$($HOME/homebrew/bin/brew shellenv)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # Add Postgresql.app binaries to path
  export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"

  # Add Redis.app binaries to path
  export PATH="/Applications/Redis.app/Contents/Resources/Vendor/redis/bin:$PATH"
fi

if [[ -n $IS_LINUX ]]; then
  # Project-local binstubs (bin/rails, bin/rake, ...)
  export PATH="./bin:$PATH"

  # Use the socket-activated ssh-agent the user session provides.
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

if [[ -n $IS_OMARCHY ]]; then
  # Keep the value the Omarchy session (uwsm) exports — /usr/share/omarchy.
  # Quickshell's `qs ipc -p` matches instances by literal path string, so
  # overriding this with the ~/.local/share/omarchy symlink makes every
  # `omarchy-shell` IPC call report "omarchy-shell is not running".
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
  export PATH="$PATH:$HOME/.local/share/omarchy/bin"
fi

########## ALIASES ##########

# Tmux aliases
alias tml="tmux list-sessions"
alias tma="tmux -2 attach -t $1"
alias tmk="tmux kill-session -t $1"

# Start tmux session for MCPs
alias tmcp="tmux new-session -s mcp"

# Other aliases
alias lzd='lazydocker'
alias clean-dir='find . -name "*.orig" -print0 -delete; find . -name "*.un~" -print0 -delete; find . -name "*.orig" -print0 -delete; find . -name "*.DS_Store"; find . -name "*.swp" -print0 -delete; find . -name "*.log" -print0 -delete'

# eza aliases
# alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --icons=always --no-user --no-permissions"

# zoxide aliases
alias cd="z"

# Git aliases
alias gfp="git fetch --prune && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs -r git branch -D"

# Add SSH key to ssh-agent
alias ssh-add-keys="ssh-add -l > /dev/null 2>&1 || ssh-add"

if [[ -n $IS_LINUX ]]; then
  # macOS muscle memory
  alias open="xdg-open"
fi

if [[ -n $IS_OMARCHY ]]; then
  # Interactive package picker over the repos + AUR
  alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"
fi

# `pbcopy` / `pbpaste` are deliberately NOT aliases — they are scripts in bin/
# that dispatch to the native macOS tools, wl-copy/wl-paste under Wayland,
# xclip under X11, or an OSC 52 escape over SSH. Scripts don't inherit shell
# aliases, so this is what lets the helpers in bin/ work on every machine.

########## FUNCTIONS ##########

# Compression
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

if [[ -n $IS_LINUX ]]; then
  # Create a desktop launcher for a web app
  web2app() {
    if [ "$#" -ne 3 ]; then
      echo "Usage: web2app <AppName> <AppURL> <IconURL> (IconURL must be in PNG -- use https://dashboardicons.com)"
      return 1
    fi

    local APP_NAME="$1"
    local APP_URL="$2"
    local ICON_URL="$3"
    local ICON_DIR="$HOME/.local/share/applications/icons"
    local DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"
    local ICON_PATH="${ICON_DIR}/${APP_NAME}.png"

    mkdir -p "$ICON_DIR"

    if ! curl -sL -o "$ICON_PATH" "$ICON_URL"; then
      echo "Error: Failed to download icon."
      return 1
    fi

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=$APP_NAME
Exec=chromium --new-window --ozone-platform=wayland --app="$APP_URL" --name="$APP_NAME" --class="$APP_NAME"
Terminal=false
Type=Application
Icon=$ICON_PATH
StartupNotify=true
EOF

    chmod +x "$DESKTOP_FILE"
  }

  web2app-remove() {
    if [ "$#" -ne 1 ]; then
      echo "Usage: web2app-remove <AppName>"
      return 1
    fi

    local APP_NAME="$1"
    local ICON_DIR="$HOME/.local/share/applications/icons"
    local DESKTOP_FILE="$HOME/.local/share/applications/${APP_NAME}.desktop"
    local ICON_PATH="${ICON_DIR}/${APP_NAME}.png"

    rm "$DESKTOP_FILE"
    rm "$ICON_PATH"
  }
fi

########## INIT ##########

# Initialize the completion system
autoload -Uz compinit
compinit

# Add the git plugin directory to the fpath
fpath=(~/.zsh/git $fpath)
source ~/.zsh/git/git.plugin.zsh

# Starship Initialization
eval "$(starship init zsh)"

if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v fzf &> /dev/null; then
  # fzf Initialization
  eval "$(fzf --zsh)"

  # -- Use fd instead of fzf --
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

  # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
  # - The first argument to the function ($1) is the base path to start traversal
  # - See the source code (completion.{bash,zsh}) for the details.
  _fzf_compgen_path() {
    fd --hidden --exclude .git . "$1"
  }

  # Use fd to generate the list for directory completion
  _fzf_compgen_dir() {
    fd --type=d --hidden --exclude .git . "$1"
  }

  export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

  # Advanced customization of fzf options via _fzf_comprun function
  # - The first argument to the function is the name of the command.
  # - You should make sure to pass the rest of the arguments to fzf.
  _fzf_comprun() {
    local command=$1
    shift

    case "$command" in
      cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
      export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
      ssh)          fzf --preview 'dig {}'                   "$@" ;;
      *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
    esac
  }
fi

# Load zsh-autosuggestions and zsh-syntax-highlighting.
# Homebrew on macOS, /usr/share on Arch, and the copies vendored under ~/.zsh
# as the last resort. Those two directories are gitignored, so on a fresh clone
# only the packaged locations exist — hence the search rather than a hard path.
typeset -a _zsh_plugin_dirs=(/usr/share/zsh/plugins ~/.zsh)
if [[ -n $IS_MACOS ]] && command -v brew &> /dev/null; then
  _zsh_plugin_dirs=("$(brew --prefix)/share" $_zsh_plugin_dirs)
fi

for _dir in $_zsh_plugin_dirs; do
  _plugin="$_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r $_plugin ]] && source "$_plugin" && break
done

# Syntax highlighting must be sourced last, after everything else has defined
# its widgets, or it will not wrap them. It also needs its highlighters/
# directory beside it — sourcing a lone .zsh file aborts the shell startup with
# "failed loading highlighters", so check for the directory before sourcing.
for _dir in $_zsh_plugin_dirs; do
  _plugin="$_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -r $_plugin && -d $_dir/zsh-syntax-highlighting/highlighters ]] && source "$_plugin" && break
done

unset _dir _plugin _zsh_plugin_dirs
