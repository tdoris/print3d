#!/usr/bin/env bash
# Export one or more .scad files to STL in exports/.
# Usage: scripts/export.sh scad/foo/foo.scad [scad/bar/bar.scad ...]
#        scripts/export.sh --all
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p exports
if [[ "${1:-}" == "--all" ]]; then
  set -- $(find scad -name '*.scad' -not -path 'scad/lib/*')
fi
for src in "$@"; do
  name="$(basename "${src%.scad}")"
  echo "==> $src -> exports/$name.stl"
  openscad -q --export-format binstl -o "exports/$name.stl" "$src"
done
