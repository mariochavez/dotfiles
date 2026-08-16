#!/usr/bin/env bash
# apply-settings.sh — merge this repo's Claude Code preferences into
# ~/.claude/settings.json.
#
#   ./apply-settings.sh            apply
#   ./apply-settings.sh --dry-run  show the diff, change nothing
#
# Why a script instead of stowing settings.json: Claude Code rewrites that file
# in place as you work — changing model, toggling a plugin, running
# /auto-mode-setup. Symlinking it means every one of those edits dirties this
# repo, and a writer that replaces rather than rewrites the file silently
# breaks the link. (Claude Desktop did exactly that to its own config here.)
# So the file stays local and this asserts our keys over the top of it.
#
# Top-level keys in settings.json are REPLACED wholesale, not deep-merged: this
# repo owns each key it lists, and anything it does not list — autoMode, and
# whatever Claude Code adds in future versions — is left untouched.
set -euo pipefail

cd "$(dirname "$0")"

SOURCE="$PWD/settings.json"
TARGET="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "apply-settings: python3 required" >&2; exit 1; }
[ -f "$SOURCE" ] || { echo "apply-settings: missing $SOURCE" >&2; exit 1; }

# A symlink here is a leftover from when this package stowed settings.json.
# Writing through it would push machine-local state back into the repo.
if [ -L "$TARGET" ]; then
  echo "==> $TARGET is a symlink; replacing it with a real file"
  if [ "$DRY_RUN" -eq 0 ]; then
    cp -- "$TARGET" "$TARGET.tmp" && rm -- "$TARGET" && mv -- "$TARGET.tmp" "$TARGET"
  fi
fi

DRY_RUN="$DRY_RUN" SOURCE="$SOURCE" TARGET="$TARGET" python3 - <<'PY'
import json, os, sys, collections

source, target = os.environ["SOURCE"], os.environ["TARGET"]
dry_run = os.environ["DRY_RUN"] == "1"

with open(source) as fh:
    desired = json.load(fh, object_pairs_hook=collections.OrderedDict)

current = collections.OrderedDict()
if os.path.exists(target):
    try:
        with open(target) as fh:
            current = json.load(fh, object_pairs_hook=collections.OrderedDict)
    except json.JSONDecodeError as exc:
        sys.exit(f"apply-settings: {target} is not valid JSON ({exc}); fix or move it first")

changed = [k for k, v in desired.items() if current.get(k) != v]

if not changed:
    print("==> already up to date")
    sys.exit(0)

for key in changed:
    before = json.dumps(current[key]) if key in current else None
    after = json.dumps(desired[key])
    trim = lambda s: s if s is None or len(s) <= 68 else s[:65] + "..."
    print(f"==> {key}")
    if before is not None:
        print(f"      - {trim(before)}")
    print(f"      + {trim(after)}")

if dry_run:
    print(f"==> dry run: {len(changed)} key(s) would change in {target}")
    sys.exit(0)

merged = collections.OrderedDict(current)
merged.update(desired)

os.makedirs(os.path.dirname(target), exist_ok=True)
# Write through any remaining path rather than rename-over, and keep a copy of
# whatever was there before.
if os.path.exists(target):
    with open(target) as fh:
        backup = fh.read()
    with open(target + ".bak", "w") as fh:
        fh.write(backup)

with open(target, "w") as fh:
    json.dump(merged, fh, indent=2)
    fh.write("\n")

print(f"==> merged {len(changed)} key(s) into {target}")
PY
