#!/usr/bin/env bash
# Pull the latest viewer pages from the dev repo into site/.
# site/config.js is deploy-specific (points at R2) and is never overwritten.
set -euo pipefail
SRC="${1:-$HOME/git/embedded-catalog-viz/viewer}"
DST="$(cd "$(dirname "$0")/.." && pwd)/site"
cp "$SRC/index.html" "$SRC/timelapse.html" "$DST/"
mkdir -p "$DST/fonts" && cp "$SRC"/fonts/*.woff2 "$DST/fonts/"
echo "copied index.html + timelapse.html + fonts/ from $SRC -> $DST (config.js untouched)"
