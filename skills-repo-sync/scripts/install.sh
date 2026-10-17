#!/usr/bin/env bash
# Links every skill in a skills repo into your agents' skills folders, so the git clone
# is the live copy: edit skills in the clone, sync with git pull / git push.
#
# A skill is a top-level folder containing SKILL.md. Anything else (archive/, bundles of
# nested skills, docs) is not linked. Retire a skill by moving it out of the top level,
# e.g. into archive/; the next run removes its links.
#
#   ./install.sh               link all skills; remove links to skills that are gone
#   ./install.sh --uninstall   remove every link that points into this repo
#   ./install.sh --repo DIR    act on another clone (default: the folder this script is in)
#
# Targets: $SKILL_DIRS (colon-separated) if set; otherwise ~/.agents/skills, plus
# ~/.claude/skills and ~/.gemini/config/skills when those folders' apps are installed.
# Existing folders and links you made yourself are never replaced; they're reported.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MODE=install
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE=uninstall ;;
    --repo) shift; REPO="$(cd "${1:?--repo needs a folder}" && pwd -P)" ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -n "${SKILL_DIRS:-}" ]; then
  IFS=: read -r -a TARGETS <<< "$SKILL_DIRS"
else
  TARGETS=("$HOME/.agents/skills")
  [ -d "$HOME/.claude" ] && TARGETS+=("$HOME/.claude/skills")
  [ -d "$HOME/.gemini/config" ] && TARGETS+=("$HOME/.gemini/config/skills")
fi

# Where a link really ends up (following chains), or "" if it's broken.
resolved() { (cd -P "$1" 2>/dev/null && pwd) || true; }
# True if a link is ours: it resolves into the repo, or (broken) its text names the repo.
ours() {
  local r; r="$(resolved "$1")"
  if [ -n "$r" ]; then [[ "$r" == "$REPO"/* ]]; else [[ "$(readlink "$1")" == "$REPO"/* ]]; fi
}

SKILLS=()
for d in "$REPO"/*/; do
  [ -f "$d/SKILL.md" ] && SKILLS+=("$(basename "$d")")
done

linked=0; pruned=0; skipped=()
for target in "${TARGETS[@]}"; do
  mkdir -p "$target"

  # Remove our links whose skill is gone (or all of ours, when uninstalling).
  for link in "$target"/*; do
    [ -L "$link" ] || continue
    ours "$link" || continue
    if [ "$MODE" = uninstall ] || [ ! -f "$link/SKILL.md" ]; then
      rm "$link"; pruned=$((pruned + 1))
    fi
  done
  [ "$MODE" = uninstall ] && continue

  for name in ${SKILLS[@]+"${SKILLS[@]}"}; do
    dest="$target/$name"
    if [ -L "$dest" ] && ! ours "$dest"; then
      skipped+=("$dest -> $(readlink "$dest") (another link)")
    elif [ -e "$dest" ] && [ ! -L "$dest" ]; then
      skipped+=("$dest (a real folder; move it aside to use the repo's copy)")
    else
      ln -sfn "$REPO/$name" "$dest"; linked=$((linked + 1))
    fi
  done
done

if [ "$MODE" = uninstall ]; then
  echo "Removed $pruned link(s) into $REPO."
  exit 0
fi
echo "${#SKILLS[@]} skill(s) in $REPO; $linked link(s) set in: ${TARGETS[*]}"
[ "$pruned" -gt 0 ] && echo "Removed $pruned link(s) to skills that no longer exist."
if [ "${#skipped[@]}" -gt 0 ]; then
  echo "Skipped (left untouched):"
  printf '  %s\n' ${skipped[@]+"${skipped[@]}"}
fi
echo "Sync: git -C \"$REPO\" pull   then re-run this script if skills were added, renamed or retired."
