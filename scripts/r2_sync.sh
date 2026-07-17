#!/usr/bin/env bash
# Sync the generated viz assets to R2 under the data/ prefix (mirrors the
# local serve.py layout). Idempotent: rclone only uploads new/changed files.
#
# Required env:
#   R2_S3_API              S3 endpoint, https://<account-id>.r2.cloudflarestorage.com
#   R2_ACCESS_KEY_ID       R2 API token access key
#   R2_SECRET_ACCESS_KEY   R2 API token secret
# Optional env:
#   R2_BUCKET              bucket name (default: embedded-catalog-viz)
#   DATA_DIR               local data dir (default: ~/Data/embedded-catalog-viz)
set -euo pipefail

: "${R2_S3_API:?set R2_S3_API}"
: "${R2_ACCESS_KEY_ID:?set R2_ACCESS_KEY_ID}"
: "${R2_SECRET_ACCESS_KEY:?set R2_SECRET_ACCESS_KEY}"
BUCKET="${R2_BUCKET:-embedded-catalog-viz}"
D="${DATA_DIR:-$HOME/Data/embedded-catalog-viz}"

# rclone remote "r2" defined entirely from env — no config file needed
export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ENDPOINT="$R2_S3_API"
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

COMMON=(--transfers 48 --checkers 96 --fast-list --stats 30s --stats-one-line)

echo "== small metadata JSONs =="
for f in tilemeta labels class_meta; do
  rclone copyto "$D/$f.json" "r2:$BUCKET/data/$f.json" \
    --header-upload "Cache-Control: public, max-age=3600"
done

echo "== timelapse_web (12 MB) =="
rclone sync "$D/timelapse_web" "r2:$BUCKET/data/timelapse_web" "${COMMON[@]}" \
  --header-upload "Cache-Control: public, max-age=86400"

echo "== lookup shards (2.1 GB, ~11k files) =="
rclone sync "$D/lookup" "r2:$BUCKET/data/lookup" "${COMMON[@]}" \
  --header-upload "Cache-Control: public, max-age=86400"

echo "== tiles (3.6 GB, ~620k files) =="
rclone sync "$D/tiles" "r2:$BUCKET/data/tiles" "${COMMON[@]}" \
  --header-upload "Cache-Control: public, max-age=86400"

echo "== atlas_cells shards (260 MB, ~4k files) — click-to-inspect for atlas.html =="
rclone sync "$D/atlas_cells" "r2:$BUCKET/data/atlas_cells" "${COMMON[@]}" \
  --header-upload "Cache-Control: public, max-age=86400"

echo "done. remote now:"
rclone size "r2:$BUCKET/data" --fast-list
