#!/usr/bin/env bash
# Render a component's diagram to PNG without Studio: dyad-cli draws the SVG, headless Chrome
# rasterizes it so part icons and instance labels show (ImageMagick drops them).
# Usage: [DYAD_ROOT=<library dir>] render.sh <Library.Module.Component> <out.png> [size]
# Renders from DYAD_ROOT, by default the checkout this script sits in.
# Writes <out.png> and <out.svg> and prints both paths.
set -euo pipefail
comp=$1 size=${3:-1000}
out=$(realpath -m "$2")
cli=${DYAD_CLI:-@juliacomputing/dyad-cli@3.5.0}
root=${DYAD_ROOT:-$(git -C "$(dirname "$(realpath "$0")")" rev-parse --show-toplevel)}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

npx -y "$cli" render -d "$root" "$comp" | sed -n '/<svg /,$p' > "$tmp/d.svg"
[[ -s $tmp/d.svg ]] || { echo "render.sh: dyad-cli produced no SVG for $comp" >&2; exit 1; }
cp "$tmp/d.svg" "${out%.png}.svg"

# Padding keeps ports and wires drawn outside the 1000x1000 outline in frame.
pad=$((size / 5))
{
  printf '<html><body style="margin:0;background:#fff"><div style="padding:%dpx">' "$pad"
  sed "0,/<svg /s//<svg width=\"$size\" height=\"$size\" /" "$tmp/d.svg"
  printf '</div></body></html>'
} > "$tmp/d.html"

google-chrome --headless=new --disable-gpu --hide-scrollbars --user-data-dir="$tmp/profile" \
  --window-size=$((size + 2 * pad)),$((size + 2 * pad)) --screenshot="$out" "file://$tmp/d.html" \
  2>/dev/null >&2
echo "$out"
echo "${out%.png}.svg"
