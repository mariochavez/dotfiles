#!/usr/bin/env bash
# Claude Code status line
# email │ cwd │ ⎇ branch │ model │ effort: level │ ctx used/size (pct%)

input=$(cat)

# -- Parse fields --
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
effort=$(echo "$input" | jq -r '.effort.level // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_used=$(echo "$input" | jq -r '.context_window.current_usage // {} | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
email=$(jq -r '.oauthAccount.emailAddress // empty' "$HOME/.claude.json" 2>/dev/null)
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

# -- Palette (truecolor) --
RESET="\033[0m"
SKY="\033[38;2;137;221;255m"       # email
BLUE="\033[38;2;130;170;255m"      # cwd
GREEN="\033[38;2;158;206;106m"     # branch, ctx ok
PURPLE="\033[38;2;187;154;247m"    # model
AMBER="\033[38;2;224;175;104m"     # effort, ctx warning
RED="\033[38;2;247;118;142m"       # ctx high
DIM="\033[38;2;86;95;137m"         # separators

SEP=" ${DIM}│${RESET} "

# Long paths collapse to their last two segments: …/presentaciones/punto
MAX_DIR=40
dir="${cwd/#"$HOME"/\~}"
if [ "${#dir}" -gt "$MAX_DIR" ]; then
  dir="…/$(basename "$(dirname "$dir")")/$(basename "$dir")"
fi

# 187432 -> 187k, 1000000 -> 1.0M
human() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%dk", n / 1000
    else printf "%d", n
  }'
}

# -- Build segments --
parts=()

[ -n "$email" ] && parts+=("${SKY}${email}${RESET}")
[ -n "$cwd" ] && parts+=("${BLUE}${dir}${RESET}")
[ -n "$branch" ] && parts+=("${GREEN}⎇ ${branch}${RESET}")
[ -n "$model" ] && parts+=("${PURPLE}${model}${RESET}")
[ -n "$effort" ] && parts+=("${AMBER}effort: ${effort}${RESET}")

if [ -n "$ctx_size" ]; then
  pct=${ctx_pct%.*}
  pct=${pct:-0}
  if [ "$pct" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "$pct" -ge 60 ]; then
    ctx_color="$AMBER"
  else
    ctx_color="$GREEN"
  fi
  parts+=("${ctx_color}ctx $(human "$ctx_used")/$(human "$ctx_size") (${pct}%)${RESET}")
fi

line=""
for part in "${parts[@]}"; do
  [ -n "$line" ] && line+="$SEP"
  line+="$part"
done

printf '%b\n' "$line"
