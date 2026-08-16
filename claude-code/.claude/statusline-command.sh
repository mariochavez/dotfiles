#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha inspired
# Reads JSON from stdin and outputs a formatted status line

input=$(cat)

# -- Parse fields --
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# -- Catppuccin Mocha exact hex palette via truecolor ANSI escapes --
# Lavender  #b4befe → cwd
# Mauve     #cba6f7 → git branch
# Peach     #fab387 → model
# Green     #a6e3a1 → context ok
# Peach     #fab387 → context warning (reuse)
# Red       #f38ba8 → context high
# Sapphire  #74c7ec → (reserved / future use)
# Text      #cdd6f4 → (reserved / future use)
RESET="\033[0m"
LAVENDER="\033[1;38;2;180;190;254m"   # #b4befe
MAUVE="\033[1;38;2;203;166;247m"      # #cba6f7
PEACH="\033[1;38;2;250;179;135m"      # #fab387
GREEN="\033[1;38;2;166;227;161m"      # #a6e3a1
RED="\033[1;38;2;243;139;168m"        # #f38ba8

# -- Build segments --
dir_display=$(echo "$cwd" | sed "s|$HOME|~|")
dir_part="${LAVENDER}${dir_display}${RESET}"

if [ -n "$branch" ]; then
  branch_part=" ${MAUVE}[${branch}]${RESET}"
else
  branch_part=""
fi

if [ -n "$model" ]; then
  model_part=" ${PEACH}${model}${RESET}"
else
  model_part=""
fi

remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
used_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')

if [ -n "$used" ] && [ -n "$remaining" ]; then
  # Truncate floats to integers for display
  used_int=${used%.*}
  remaining_int=${remaining%.*}
  # Red when 80%+ used, yellow when 60%+, green otherwise
  if [ "${used_int:-0}" -ge 80 ]; then
    ctx_color="$RED"
  elif [ "${used_int:-0}" -ge 60 ]; then
    ctx_color="$PEACH"
  else
    ctx_color="$GREEN"
  fi
  ctx_part=" ${ctx_color}ctx:${used_int}% (${remaining_int}% left)${RESET}"
elif [ -n "$ctx_size" ]; then
  # No messages yet — show window size so user knows it's active
  ctx_part=" ${GREEN}ctx:${ctx_size} tokens${RESET}"
else
  ctx_part=""
fi

printf '%b\n' "${dir_part}${branch_part}${model_part}${ctx_part}"
