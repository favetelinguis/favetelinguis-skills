#!/usr/bin/env bash
# Move vendor submodules to the newest upstream commit and show what changed.
#
# usage: ./update-vendor.sh [name...]   (default: every submodule under vendor/)
#
# It does not commit. The files on disk change at once, and the installed
# links point at them, so review the output, then either commit the bump or
# roll it back with `git submodule update vendor/<name>`.
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd -- "$repo"

if [[ $# -eq 0 ]]; then
  set -- $(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}' | sed 's|^vendor/||')
fi

for name in "$@"; do
  path="vendor/$name"
  git config -f .gitmodules --get "submodule.$path.url" >/dev/null || { echo "error: no submodule at $path" >&2; exit 1; }

  git submodule update --init -- "$path" >/dev/null
  old="$(git -C "$path" rev-parse HEAD)"
  git submodule update --remote -- "$path"
  new="$(git -C "$path" rev-parse HEAD)"

  if [[ "$old" == "$new" ]]; then
    echo "== $name: already up to date (${new:0:7})"
    continue
  fi

  echo "== $name: ${old:0:7} -> ${new:0:7}"
  git -C "$path" log --oneline --no-decorate "$old..$new"

  # Diffstat limited to the skills this repo links from that source.
  linked=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ "$line" == "$name":* ]] && linked+=("${line#*:}")
  done < skills.conf
  if [[ ${#linked[@]} -gt 0 ]]; then
    echo "-- changes in linked skills:"
    stat="$(git -C "$path" diff --stat "$old" "$new" -- "${linked[@]}")"
    echo "${stat:-   (none)}"
    for skill in "${linked[@]}"; do
      [[ -f "$path/$skill/SKILL.md" ]] || echo "warning: $name:$skill no longer exists upstream; edit skills.conf" >&2
    done
  fi
done

echo
git status --short -- vendor
echo "Review, then: git add vendor && git commit -m 'Bump vendor' && ./link-skills.sh"
echo "Roll back:    git submodule update vendor/<name>"
