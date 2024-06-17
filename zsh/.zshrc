export XDG_CONFIG_HOME="$HOME/.config"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# User configuration
export EDITOR="nvim"

# Add Homebrew to path
export PATH="/opt/homebrew/bin":$PATH

# Add Postgresql.app binaries to path
 export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"

# Add Redis.app binaries to path
export PATH="/Applications/Redis.app/Contents/Resources/Vendor/redis/bin:$PATH"

# Add local bin folder
export PATH="$HOME/bin:$PATH"

# Tmux aliases
alias tml="tmux list-sessions"
alias tma="tmux -2 attach -t $1"
alias tmk="tmux kill-session -t $1"

# Ruby and RBenv config options
eval "$(rbenv init -)"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# Other aliases
alias lzd='lazydocker'
alias clean-dir='find . -name "*.orig" -print0 -delete; find . -name "*.un~" -print0 -delete; find . -name "*.orig" -print0 -delete; find . -name "*.DS_Store"; find . -name "*.swp" -print0 -delete; find . -name "*.log" -print0 -delete'

# >>> conda initialize >>>
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
    p10k segment -i '' -f 208 -t $CONDA_DEFAULT_ENV
  fi
}
# <<< conda initialize <<<

eval "$(fzf --zsh)"

# Starship Initialization
eval "$(starship init zsh)"

# Initialize the completion system
autoload -Uz compinit
compinit

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Add the git plugin directory to the fpath
fpath=(~/.zsh/git $fpath)
source ~/.zsh/git/git.plugin.zsh

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

# alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias ls="eza --color=always --long --git --icons=always --no-user --no-permissions"

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

alias cd="z"
alias gfp="git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d"
BAT_THEME="Catppuccin Mocha"
