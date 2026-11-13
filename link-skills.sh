#!/usr/bin/env bash
# Link the skills selected in skills.conf into ~/.agents/skills, and the
# executables listed below from scripts/ into ~/.local/bin.
#
# Safe to rerun. It replaces selected symlinks, refuses to overwrite real files
# or directories, and only removes deselected links that point into this repo.
# Unrelated skills stay installed.
#
# Override the destinations with AGENT_SKILLS_DIR and BIN_DIR (useful for a dry
# run against a temporary directory).
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config="$repo/skills.conf"
destination="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
bin_destination="${BIN_DIR:-$HOME/.local/bin}"

# Executables in scripts/ to link into $bin_destination.
scripts=(
  wt-review
)

die() { echo "error: $*" >&2; exit 1; }

# Resolve "<source>:<path>" to an absolute skill folder.
resolve() {
  local source="${1%%:*}" path="${1#*:}"
  [[ "$1" == *:* && -n "$source" && -n "$path" ]] || die "bad entry '$1' in skills.conf (want <source>:<path>)"
  if [[ "$source" == self ]]; then
    echo "$repo/$path"
  else
    [[ -d "$repo/vendor/$source" ]] || die "unknown source '$source' in '$1': no vendor/$source submodule"
    echo "$repo/vendor/$source/$path"
  fi
}

# Read and validate the selection before touching anything.
names=()
srcs=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line//[[:space:]]/}"
  [[ -n "$line" ]] || continue

  src="$(resolve "$line")"
  if [[ ! -f "$src/SKILL.md" ]]; then
    if [[ "$line" != self:* && -z "$(ls -A -- "$repo/vendor/${line%%:*}" 2>/dev/null)" ]]; then
      die "vendor/${line%%:*} is empty; run: git submodule update --init"
    fi
    die "no SKILL.md for '$line' ($src)"
  fi

  name="${src##*/}"
  for i in "${!names[@]}"; do
    [[ "${names[$i]}" != "$name" ]] || die "two entries link as '$name': ${srcs[$i]#"$repo/"} and ${src#"$repo/"}"
  done
  names+=("$name")
  srcs+=("$src")
done < "$config"

# Keep the destination a real directory so links cannot land in the repo.
[[ ! -L "$destination" ]] || die "refusing symlinked destination: $destination"
mkdir -p -- "$destination"

for i in "${!names[@]}"; do
  target="$destination/${names[$i]}"
  [[ ! -e "$target" || -L "$target" ]] || die "refusing to overwrite: $target"
  ln -sfn -- "${srcs[$i]}" "$target"
  echo "Linked ${srcs[$i]#"$repo/"}"
done

# Remove links into this repo that are no longer selected.
for target in "$destination"/*; do
  [[ -L "$target" ]] || continue
  link="$(readlink -- "$target")"
  [[ "$link" == "$repo"/* ]] || continue
  selected=false
  for src in "${srcs[@]}"; do
    [[ "$link" != "$src" ]] || { selected=true; break; }
  done
  if [[ "$selected" == false ]]; then
    unlink -- "$target"
    echo "Unlinked ${link#"$repo/"}"
  fi
done

# ~/.local/bin is on PATH by default on most Linux distros; add it on macOS.
mkdir -p -- "$bin_destination"

for source in "$repo"/scripts/*; do
  [[ -f "$source" ]] || continue
  name="${source##*/}"
  target="$bin_destination/$name"

  if [[ " ${scripts[*]} " == *" $name "* ]]; then
    [[ ! -e "$target" || -L "$target" ]] || die "refusing to overwrite: $target"
    chmod +x -- "$source"
    ln -sfn -- "$source" "$target"
    echo "Linked scripts/$name"
  elif [[ -L "$target" && "$(readlink -- "$target")" == "$source" ]]; then
    unlink -- "$target"
    echo "Unlinked scripts/$name"
  fi
done

if [[ ":$PATH:" != *":$bin_destination:"* ]]; then
  echo "Note: add $bin_destination to PATH, e.g. in ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
fi
