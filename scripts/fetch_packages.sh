#!/usr/bin/env bash
# Clone the TerraME packages listed in packages.lock into .packages/, each at
# its fixed commit. The commit hash is the integrity check.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$ROOT/.packages"
grep -v '^\s*#' "$ROOT/packages.lock" | while read -r name url commit; do
  [ -z "${name:-}" ] && continue
  dest="$ROOT/.packages/$name"
  if [ ! -d "$dest/.git" ]; then
    git clone --quiet "$url" "$dest"
  fi
  git -C "$dest" fetch --quiet origin "$commit" 2>/dev/null || true
  git -C "$dest" checkout --quiet "$commit"
  test "$(git -C "$dest" rev-parse HEAD)" = "$commit"
  echo "$name at $commit"
done
