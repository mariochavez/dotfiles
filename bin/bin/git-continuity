#!/bin/bash

# Git Continuity - Transfer staged work between machines
# Enhanced with Gum TUI, SCP support, and Glow/Bat previews
# Requires: git, gum (optional), scp (optional), glow/bat (optional)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/git-continuity/config"
PATCHES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/git-continuity/patches"
DEFAULT_PATCH_NAME="git-continuity-$(date +%Y%m%d-%H%M%S).patch"

# Check available tools
HAS_GUM=false
HAS_GLOW=false
HAS_BAT=false

command -v gum &>/dev/null && HAS_GUM=true
command -v glow &>/dev/null && HAS_GLOW=true
command -v bat &>/dev/null && HAS_BAT=true

# Ensure directories exist
mkdir -p "$(dirname "$CONFIG_FILE")" "$PATCHES_DIR"

function show_help() {
  cat <<EOF
Git Continuity - Sync work between machines

USAGE:
    $0 export [filename]     Create a patch from staged changes
    $0 import [filename]     Apply a patch on another machine
    $0 preview [filename]    Preview a patch file
    $0 config                Manage remote host configurations
    $0 list                  List available patches
    $0 help                  Show this help message

OPTIONS:
    --no-transfer            Skip automatic transfer prompt
    --no-preview             Skip preview prompt
    --scp <host>            Transfer via SCP to specified host
    --interactive           Force interactive mode (requires gum)

EXAMPLES:
    # Interactive export with preview
    $0 export
    
    # Export with preview and transfer
    $0 export --scp laptop
    
    # Preview changes before importing
    $0 import  # (interactive with preview)
    
    # Preview a specific patch
    $0 preview my-work.patch

NAVIGATION:
    When viewing long previews, use:
    - Space/f     : Scroll down one page
    - b           : Scroll up one page
    - Arrow keys  : Scroll line by line
    - q           : Quit preview
    - /pattern    : Search forward
    - ?pattern    : Search backward
    - n           : Next search result
    - N           : Previous search result

SETUP:
    # Enhanced TUI
    brew install gum
    
    # Beautiful previews
    brew install glow  # For formatted diffs (recommended)
    brew install bat   # Alternative: syntax-highlighted diffs
    
    # Both work together, glow preferred for diffs
EOF
}

function gum_style() {
  if [ "$HAS_GUM" = true ]; then
    gum style "$@"
  else
    echo "$@"
  fi
}

function gum_spin() {
  if [ "$HAS_GUM" = true ]; then
    gum spin --title "$1" -- "${@:2}"
  else
    echo "$1..."
    "${@:2}"
  fi
}

function gum_confirm() {
  if [ "$HAS_GUM" = true ]; then
    gum confirm "$1"
  else
    read -p "$1 (y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
  fi
}

function gum_input() {
  if [ "$HAS_GUM" = true ]; then
    gum input --placeholder "$1" --value "$2"
  else
    read -p "$1 [$2]: " input
    echo "${input:-$2}"
  fi
}

function gum_choose() {
  if [ "$HAS_GUM" = true ]; then
    gum choose "$@"
  else
    select opt in "$@"; do
      echo "$opt"
      break
    done
  fi
}

function show_diff_preview() {
  local diff_content="$1"
  local title="${2:-Diff Preview}"

  if [ "$HAS_GUM" = true ]; then
    gum_style --border rounded --padding "1 2" --bold "👁  $title"
    echo
  else
    echo "=== $title ==="
    echo
  fi

  # Count lines to determine if we need pagination
  local line_count=$(echo "$diff_content" | wc -l)
  local term_height=$(tput lines 2>/dev/null || echo 24)
  local needs_pager=false

  # If content is longer than terminal height minus some margin, use pager
  if [ "$line_count" -gt $((term_height - 10)) ]; then
    needs_pager=true
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 242 "📜 Long diff detected - entering scrollable view (press 'q' to exit)"
    else
      echo "📜 Long diff detected - use space/arrows to scroll, 'q' to exit"
    fi
    echo
  fi

  # Try glow first (best for formatted diffs)
  if [ "$HAS_GLOW" = true ]; then
    if [ "$needs_pager" = true ]; then
      echo "$diff_content" | glow --style dark --width 100 --pager
    else
      echo "$diff_content" | glow --style dark --width 100
    fi
  # Fallback to bat (syntax highlighting with built-in paging)
  elif [ "$HAS_BAT" = true ]; then
    if [ "$needs_pager" = true ]; then
      echo "$diff_content" | bat --language diff --style plain --paging always --color always
    else
      echo "$diff_content" | bat --language diff --style plain --paging never --color always
    fi
  # Final fallback to plain output with less for pagination
  else
    if [ "$needs_pager" = true ]; then
      echo "$diff_content" | sed 's/^+/\x1b[32m+/;s/^-/\x1b[31m-/;s/^@/\x1b[36m@/;s/$/\x1b[0m/' | less -R
    else
      echo "$diff_content" | sed 's/^+/\x1b[32m+/;s/^-/\x1b[31m-/;s/^@/\x1b[36m@/;s/$/\x1b[0m/'
    fi
  fi

  echo
}

function preview_changes_before_export() {
  local has_staged=false
  local has_unstaged=false

  if ! git diff --cached --quiet 2>/dev/null; then
    has_staged=true
  fi

  if ! git diff --quiet 2>/dev/null; then
    has_unstaged=true
  fi

  if [ "$has_staged" = false ] && [ "$has_unstaged" = false ]; then
    return 1
  fi

  # Create a preview of what will be in the patch
  local preview=""

  if [ "$has_staged" = true ]; then
    preview+="# Staged Changes\n\n"
    preview+="$(git diff --cached --stat)\n\n"
    preview+="$(git diff --cached)\n\n"
  fi

  if [ "$has_unstaged" = true ]; then
    preview+="# Unstaged Changes\n\n"
    preview+="$(git diff --stat)\n\n"
    preview+="$(git diff)\n\n"
  fi

  show_diff_preview "$preview" "Changes to Export"

  return 0
}

function preview_patch_file() {
  local patch_file="$1"

  if [ ! -f "$patch_file" ]; then
    if [ -f "$PATCHES_DIR/$patch_file" ]; then
      patch_file="$PATCHES_DIR/$patch_file"
    else
      echo "Error: Patch file not found: $patch_file"
      return 1
    fi
  fi

  # Extract metadata
  local metadata=$(sed -n '/# Git Continuity Patch/,/---METADATA-END---/p' "$patch_file" | grep "^# " | sed 's/^# //')

  if [ "$HAS_GUM" = true ]; then
    gum_style --border rounded --padding "1 2" --bold "📋 Patch Information"
    echo "$metadata" | gum format
    echo
  else
    echo "=== Patch Information ==="
    echo "$metadata"
    echo
  fi

  # Show stats
  if [ "$HAS_GUM" = true ]; then
    gum_style --foreground 212 "📊 Change Summary:"
  else
    echo "=== Change Summary ==="
  fi

  local staged_count=$(grep -c "^diff --git" <(sed -n '/---STAGED-CHANGES---/,/---STAGED-END---/p' "$patch_file") 2>/dev/null || echo "0")
  local unstaged_count=$(grep -c "^diff --git" <(sed -n '/---UNSTAGED-CHANGES---/,/---UNSTAGED-END---/p' "$patch_file") 2>/dev/null || echo "0")

  echo "  Staged files: $staged_count"
  echo "  Unstaged files: $unstaged_count"
  echo

  # Preview staged changes
  if grep -q "---STAGED-CHANGES---" "$patch_file"; then
    local staged_diff=$(sed -n '/---STAGED-CHANGES---/,/---STAGED-END---/p' "$patch_file" | sed '1d;$d')
    local staged_stat=$(echo "$staged_diff" | git apply --stat 2>/dev/null || echo "Could not generate stats")

    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 212 "📝 Staged Changes:"
      echo "$staged_stat"
      echo
    else
      echo "=== Staged Changes ==="
      echo "$staged_stat"
      echo
    fi

    if gum_confirm "View full staged diff?"; then
      show_diff_preview "$staged_diff" "Staged Changes Detail"
    fi
  fi

  # Preview unstaged changes
  if grep -q "---UNSTAGED-CHANGES---" "$patch_file"; then
    local unstaged_diff=$(sed -n '/---UNSTAGED-CHANGES---/,/---UNSTAGED-END---/p' "$patch_file" | sed '1d;$d')
    local unstaged_stat=$(echo "$unstaged_diff" | git apply --stat 2>/dev/null || echo "Could not generate stats")

    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 212 "📝 Unstaged Changes:"
      echo "$unstaged_stat"
      echo
    else
      echo "=== Unstaged Changes ==="
      echo "$unstaged_stat"
      echo
    fi

    if gum_confirm "View full unstaged diff?"; then
      show_diff_preview "$unstaged_diff" "Unstaged Changes Detail"
    fi
  fi

  # Show untracked files
  if grep -q "---UNTRACKED-FILES---" "$patch_file"; then
    echo
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 214 "📄 Untracked Files (not included):"
    else
      echo "=== Untracked Files (not included) ==="
    fi
    sed -n '/---UNTRACKED-FILES---/,/---UNTRACKED-END---/p' "$patch_file" | sed '1d;$d'
  fi
}

function load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  fi
}

function save_host() {
  local name="$1"
  local host="$2"
  local path="$3"

  if [ -f "$CONFIG_FILE" ]; then
    sed -i "/^HOST_${name}_/d" "$CONFIG_FILE"
  fi

  echo "HOST_${name}_HOST=\"$host\"" >>"$CONFIG_FILE"
  echo "HOST_${name}_PATH=\"$path\"" >>"$CONFIG_FILE"
}

function list_hosts() {
  if [ ! -f "$CONFIG_FILE" ]; then
    return
  fi

  local hosts=()
  while IFS= read -r line; do
    if [[ $line =~ ^HOST_([^_]+)_HOST ]]; then
      hosts+=("${BASH_REMATCH[1]}")
    fi
  done < <(grep "^HOST_" "$CONFIG_FILE" | sort -u)

  printf '%s\n' "${hosts[@]}" | sort -u
}

function get_host_config() {
  local name="$1"
  load_config

  local host_var="HOST_${name}_HOST"
  local path_var="HOST_${name}_PATH"

  echo "${!host_var}|${!path_var}"
}

function config_hosts() {
  if [ "$HAS_GUM" = false ]; then
    echo "Interactive config requires gum. Install from: https://github.com/charmbracelet/gum"
    exit 1
  fi

  gum_style --border rounded --padding "1 2" --bold "🔧 Git Continuity Configuration"
  echo

  while true; do
    action=$(gum choose "Add remote host" "List configured hosts" "Remove host" "Back")

    case "$action" in
    "Add remote host")
      echo
      gum_style --foreground 212 "Add Remote Host"
      name=$(gum input --placeholder "Host nickname (e.g., laptop, desktop)")
      if [ -z "$name" ]; then continue; fi

      host=$(gum input --placeholder "SSH host (e.g., user@hostname or ~/.ssh/config alias)")
      if [ -z "$host" ]; then continue; fi

      path=$(gum input --placeholder "Remote path" --value "~/git-continuity-patches")

      save_host "$name" "$host" "$path"
      gum_style --foreground 212 "✓ Saved host '$name'"
      echo
      ;;

    "List configured hosts")
      echo
      gum_style --foreground 212 "Configured Hosts:"
      local hosts_list=($(list_hosts))
      if [ ${#hosts_list[@]} -eq 0 ]; then
        echo "  No hosts configured"
      else
        for h in "${hosts_list[@]}"; do
          config=$(get_host_config "$h")
          IFS='|' read -r host path <<<"$config"
          echo "  $h: $host → $path"
        done
      fi
      echo
      ;;

    "Remove host")
      local hosts_list=($(list_hosts))
      if [ ${#hosts_list[@]} -eq 0 ]; then
        echo "No hosts configured"
        continue
      fi
      echo
      host_to_remove=$(gum choose "${hosts_list[@]}")
      if [ -n "$host_to_remove" ]; then
        sed -i "/^HOST_${host_to_remove}_/d" "$CONFIG_FILE"
        gum_style --foreground 212 "✓ Removed host '$host_to_remove'"
      fi
      echo
      ;;

    "Back")
      break
      ;;
    esac
  done
}

function scp_transfer() {
  local patch_file="$1"
  local dest="$2"

  if config=$(get_host_config "$dest"); then
    IFS='|' read -r ssh_host remote_path <<<"$config"
    if [ -z "$ssh_host" ]; then
      ssh_host="$dest"
      remote_path="~/git-continuity-patches"
    fi
  else
    ssh_host="$dest"
    remote_path="~/git-continuity-patches"
  fi

  local filename=$(basename "$patch_file")

  if [ "$HAS_GUM" = true ]; then
    gum_style --foreground 212 "📤 Transferring to $dest..."
  else
    echo "Transferring $filename to $dest..."
  fi

  ssh "$ssh_host" "mkdir -p '$remote_path'" 2>/dev/null || true

  if scp "$patch_file" "${ssh_host}:${remote_path}/${filename}"; then
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 212 "✓ Successfully transferred to ${ssh_host}:${remote_path}/${filename}"
    else
      echo "✓ Transfer complete: ${ssh_host}:${remote_path}/${filename}"
    fi
    return 0
  else
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 196 "✗ Transfer failed"
    else
      echo "✗ Transfer failed"
    fi
    return 1
  fi
}

function export_patch() {
  local patch_file="$1"
  local skip_transfer="${2:-false}"
  local scp_dest="${3:-}"
  local skip_preview="${4:-false}"

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
  fi

  local has_staged=false
  local has_unstaged=false

  if ! git diff --cached --quiet 2>/dev/null; then
    has_staged=true
  fi

  if ! git diff --quiet 2>/dev/null; then
    has_unstaged=true
  fi

  if [ "$has_staged" = false ] && [ "$has_unstaged" = false ]; then
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 196 "No changes to export"
    else
      echo "No changes to export (nothing staged or modified)"
    fi
    exit 1
  fi

  # Preview before export
  if [ "$skip_preview" = false ]; then
    if preview_changes_before_export; then
      echo
      if ! gum_confirm "Proceed with export?"; then
        echo "Export cancelled"
        exit 0
      fi
    fi
  fi

  # Interactive filename input with gum
  if [ "$HAS_GUM" = true ] && [ -z "$patch_file" ]; then
    echo
    gum_style --border rounded --padding "1 2" --bold "📦 Export Git Changes"
    echo
    patch_file=$(gum input --placeholder "Patch filename" --value "$DEFAULT_PATCH_NAME")
  else
    patch_file="${patch_file:-$DEFAULT_PATCH_NAME}"
  fi

  if [[ ! "$patch_file" =~ \.patch$ ]]; then
    patch_file="${patch_file}.patch"
  fi

  local full_path="$PATCHES_DIR/$patch_file"

  if [ "$HAS_GUM" = true ]; then
    gum_style --foreground 212 "Creating patch: $patch_file"
  else
    echo "Creating patch: $patch_file"
  fi

  {
    echo "# Git Continuity Patch"
    echo "# Created: $(date)"
    echo "# Branch: $(git branch --show-current)"
    echo "# Commit: $(git rev-parse HEAD)"
    echo "# Repository: $(basename $(git rev-parse --show-toplevel))"
    echo "---METADATA-END---"

    if [ "$has_staged" = true ]; then
      echo "---STAGED-CHANGES---"
      git diff --cached --binary
      echo "---STAGED-END---"
    fi

    if [ "$has_unstaged" = true ]; then
      echo "---UNSTAGED-CHANGES---"
      git diff --binary
      echo "---UNSTAGED-END---"
    fi

    local untracked=$(git ls-files --others --exclude-standard)
    if [ -n "$untracked" ]; then
      echo "---UNTRACKED-FILES---"
      echo "$untracked"
      echo "---UNTRACKED-END---"
    fi

  } >"$full_path"

  if [ "$HAS_GUM" = true ]; then
    echo
    gum_style --foreground 212 --bold "✓ Patch created successfully"
    echo
    gum_style --border rounded "  📍 Location: $full_path"
    [ "$has_staged" = true ] && echo "  ✓ Staged changes included"
    [ "$has_unstaged" = true ] && echo "  ✓ Unstaged changes included"
  else
    echo "✓ Patch created: $full_path"
  fi

  # Handle SCP transfer
  if [ -n "$scp_dest" ]; then
    echo
    scp_transfer "$full_path" "$scp_dest"
  elif [ "$skip_transfer" = false ] && [ "$HAS_GUM" = true ]; then
    echo
    if gum_confirm "Transfer patch to remote host?"; then
      echo
      local hosts_list=($(list_hosts))

      if [ ${#hosts_list[@]} -gt 0 ]; then
        hosts_list+=("Enter custom host...")
        local choice=$(gum choose "${hosts_list[@]}")

        if [ "$choice" = "Enter custom host..." ]; then
          choice=$(gum input --placeholder "SSH host (e.g., user@hostname)")
        fi
      else
        gum_style --foreground 214 "No hosts configured. Enter SSH destination:"
        choice=$(gum input --placeholder "user@hostname")
      fi

      if [ -n "$choice" ]; then
        echo
        scp_transfer "$full_path" "$choice"
      fi
    fi
  fi

  echo
  if [ "$HAS_GUM" = true ]; then
    gum_style --foreground 242 "On the remote machine, run:"
    gum_style --foreground 212 "  git-continuity import $patch_file"
  else
    echo "On the remote machine, run:"
    echo "  git-continuity import $patch_file"
  fi
}

function list_patches() {
  if [ "$HAS_GUM" = true ]; then
    gum_style --border rounded --padding "1 2" --bold "📚 Available Patches"
    echo
  else
    echo "Available patches:"
  fi

  local patches=($(ls -t "$PATCHES_DIR"/*.patch 2>/dev/null || true))

  if [ ${#patches[@]} -eq 0 ]; then
    echo "  No patches found in $PATCHES_DIR"
    return
  fi

  for patch in "${patches[@]}"; do
    local name=$(basename "$patch")
    local date=$(stat -c %y "$patch" 2>/dev/null || stat -f %Sm "$patch" 2>/dev/null)

    if [ "$HAS_GUM" = true ]; then
      echo "  • $name"
      gum_style --foreground 242 "    $(echo $date | cut -d'.' -f1)"
    else
      echo "  $name ($date)"
    fi
  done
}

function import_patch() {
  local patch_file="$1"
  local skip_preview="${2:-false}"

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
  fi

  # Interactive patch selection with gum
  if [ "$HAS_GUM" = true ] && [ -z "$patch_file" ]; then
    gum_style --border rounded --padding "1 2" --bold "📥 Import Git Changes"
    echo

    local patches=($(ls -t "$PATCHES_DIR"/*.patch 2>/dev/null | xargs -n1 basename || true))

    if [ ${#patches[@]} -eq 0 ]; then
      gum_style --foreground 196 "No patches found in $PATCHES_DIR"
      exit 1
    fi

    patches+=("Browse for file...")
    local choice=$(gum choose "${patches[@]}")

    if [ "$choice" = "Browse for file..." ]; then
      patch_file=$(gum input --placeholder "Path to patch file")
    else
      patch_file="$PATCHES_DIR/$choice"
    fi
  fi

  if [ -z "$patch_file" ]; then
    echo "Error: Please specify a patch file to import"
    exit 1
  fi

  if [ ! -f "$patch_file" ] && [ -f "$PATCHES_DIR/$patch_file" ]; then
    patch_file="$PATCHES_DIR/$patch_file"
  fi

  if [ ! -f "$patch_file" ]; then
    echo "Error: Patch file not found: $patch_file"
    exit 1
  fi

  # Preview before import
  if [ "$skip_preview" = false ]; then
    preview_patch_file "$patch_file"
    echo
    if ! gum_confirm "Apply this patch?"; then
      echo "Import cancelled"
      exit 0
    fi
  fi

  echo

  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    if [ "$HAS_GUM" = true ]; then
      gum_style --foreground 214 "⚠ Warning: You have uncommitted changes"
      if ! gum_confirm "Continue anyway?"; then
        exit 1
      fi
    else
      echo "Warning: You have uncommitted changes"
      if ! gum_confirm "Continue anyway?"; then
        exit 1
      fi
    fi
  fi

  # Apply changes
  if grep -q "---STAGED-CHANGES---" "$patch_file"; then
    if [ "$HAS_GUM" = true ]; then
      gum_spin "Applying staged changes" \
        sh -c "sed -n '/---STAGED-CHANGES---/,/---STAGED-END---/p' '$patch_file' | sed '1d;\$d' | git apply --cached --binary"
      gum_style --foreground 212 "✓ Staged changes applied"
    else
      echo "Applying staged changes..."
      sed -n '/---STAGED-CHANGES---/,/---STAGED-END---/p' "$patch_file" |
        sed '1d;$d' |
        git apply --cached --binary
      echo "✓ Staged changes applied"
    fi
  fi

  if grep -q "---UNSTAGED-CHANGES---" "$patch_file"; then
    if [ "$HAS_GUM" = true ]; then
      gum_spin "Applying unstaged changes" \
        sh -c "sed -n '/---UNSTAGED-CHANGES---/,/---UNSTAGED-END---/p' '$patch_file' | sed '1d;\$d' | git apply --binary"
      gum_style --foreground 212 "✓ Unstaged changes applied"
    else
      echo "Applying unstaged changes..."
      sed -n '/---UNSTAGED-CHANGES---/,/---UNSTAGED-END---/p' "$patch_file" |
        sed '1d;$d' |
        git apply --binary
      echo "✓ Unstaged changes applied"
    fi
  fi

  echo
  if [ "$HAS_GUM" = true ]; then
    gum_style --foreground 212 --bold "✓ Patch applied successfully!"
    echo
    gum_style --foreground 242 "Next steps:"
    echo "  • Review: git status"
    echo "  • Continue working"
    echo "  • Commit when ready: git commit"
  else
    echo "✓ Patch applied successfully!"
    echo ""
    echo "Next steps:"
    echo "  - Review changes: git status"
    echo "  - Continue working"
    echo "  - Commit when ready: git commit"
  fi
}

# Parse options
SKIP_TRANSFER=false
SKIP_PREVIEW=false
SCP_DEST=""
FORCE_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
  --no-transfer)
    SKIP_TRANSFER=true
    shift
    ;;
  --no-preview)
    SKIP_PREVIEW=true
    shift
    ;;
  --scp)
    SCP_DEST="$2"
    shift 2
    ;;
  --interactive)
    FORCE_INTERACTIVE=true
    shift
    ;;
  export | import | preview | config | list | help | --help | -h)
    COMMAND="$1"
    shift
    break
    ;;
  *)
    COMMAND="$1"
    shift
    break
    ;;
  esac
done

# Main script logic
case "${COMMAND:-}" in
export)
  export_patch "$1" "$SKIP_TRANSFER" "$SCP_DEST" "$SKIP_PREVIEW"
  ;;
import)
  import_patch "$1" "$SKIP_PREVIEW"
  ;;
preview)
  if [ -z "$1" ]; then
    echo "Usage: $0 preview <patch-file>"
    exit 1
  fi
  preview_patch_file "$1"
  ;;
config)
  config_hosts
  ;;
list)
  list_patches
  ;;
help | --help | -h)
  show_help
  ;;
*)
  if [ "$HAS_GUM" = false ]; then
    echo "Error: Invalid command"
    echo ""
    show_help
    exit 1
  fi

  # Interactive mode with gum
  gum_style --border rounded --padding "1 2" --bold "🔄 Git Continuity"
  echo
  action=$(gum choose "Export (create patch)" "Import (apply patch)" "Preview patch" "List patches" "Configure hosts" "Help")
  echo

  case "$action" in
  "Export (create patch)")
    export_patch "" "$SKIP_TRANSFER" "$SCP_DEST" "$SKIP_PREVIEW"
    ;;
  "Import (apply patch)")
    import_patch "" "$SKIP_PREVIEW"
    ;;
  "Preview patch")
    local patches=($(ls -t "$PATCHES_DIR"/*.patch 2>/dev/null | xargs -n1 basename || true))
    if [ ${#patches[@]} -eq 0 ]; then
      gum_style --foreground 196 "No patches found"
      exit 1
    fi
    patches+=("Browse for file...")
    local choice=$(gum choose "${patches[@]}")
    if [ "$choice" = "Browse for file..." ]; then
      choice=$(gum input --placeholder "Path to patch file")
    else
      choice="$PATCHES_DIR/$choice"
    fi
    preview_patch_file "$choice"
    ;;
  "List patches")
    list_patches
    ;;
  "Configure hosts")
    config_hosts
    ;;
  "Help")
    show_help
    ;;
  esac
  ;;
esac
