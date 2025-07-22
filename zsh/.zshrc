########## SHELL CONFIGURATION ##########

# Config directory
export XDG_CONFIG_HOME="$HOME/.config"

# User configuration
export EDITOR="nvim"

# Bat theme
export BAT_THEME="Catppuccin Mocha"

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

# Add local bin folder
export PATH="$HOME/bin:$PATH"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific configurations
    
    # Add Homebrew to path
    export PATH="/opt/homebrew/bin":$PATH
    
    # Add Postgresql.app binaries to path
    export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
    
    # Add Redis.app binaries to path
    export PATH="/Applications/Redis.app/Contents/Resources/Vendor/redis/bin:$PATH"
else
    # Set complete path
    export PATH="./bin:$HOME/.local/bin:$HOME/.local/share/omarchy/bin:$PATH"
fi

########## ALIASES ##########
 
# Tmux aliases
alias tml="tmux list-sessions"
alias tma="tmux -2 attach -t $1"
alias tmk="tmux kill-session -t $1"

# Other aliases
alias lzd='lazydocker'
alias clean-dir='find . -name "*.orig" -print0 -delete; find . -name "*.un~" -print0 -delete; find . -name "*.orig" -print0 -delete; find . -name "*.DS_Store"; find . -name "*.swp" -print0 -delete; find . -name "*.log" -print0 -delete'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

# eza aliases
# alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --icons=always --no-user --no-permissions"

# zoxide aliases
alias cd="z"

# Git aliases
alias gfp="git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d"

# Add SSH key to ssh-agent
alias ssh-add-keys="ssh-add -l > /dev/null 2>&1 || ssh-add"

# Start tmux session for MCPs
alias tmcp="tmux new-session -s mcp"


if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Shared clipboard
  alias pbcopy="~/bin/osc52.sh"
fi

########## FUNCTIONS ##########

# Compression
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

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

########## INIT ##########

# Initialize the completion system
autoload -Uz compinit
compinit

# Load zsh-autosuggestions and zsh-syntax-highlighting based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use Homebrew versions
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
    # Linux - use local versions
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

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

# Load SSH Agent on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# Ruby and RBenv config options - only if rbenv is installed
if command -v rbenv &> /dev/null; then
    eval "$(rbenv init -)"
    # export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

# >>> conda initialize >>>
# Only initialize conda if it's installed
if [[ -f "/opt/homebrew/Caskroom/miniconda/base/bin/conda" ]] || [[ -f "$HOME/miniconda3/bin/conda" ]] || [[ -f "$HOME/anaconda3/bin/conda" ]]; then
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
            . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
        else
            export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
        fi
    fi
    unset __conda_setup

    function prompt_conda_environment() {
      if [ -n "$CONDA_DEFAULT_ENV" ]; then
        p10k segment -i '' -f 208 -t $CONDA_DEFAULT_ENV
      fi
    }
fi
# <<< conda initialize <<<
