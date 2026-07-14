#!/usr/bin/env bash
# One-time R2 bucket setup: create the bucket and set CORS so the GitHub Pages
# origin can fetch() the JSON/webp assets. Safe to re-run.
#
# Required env:
#   R2_S3_API              S3 endpoint, https://<account-id>.r2.cloudflarestorage.com
#   R2_ACCESS_KEY_ID       R2 API token access key (32 hex chars)
#   R2_SECRET_ACCESS_KEY   R2 API token secret
# Optional env:
#   R2_BUCKET              bucket name (default: embedded-catalog-viz)
#   PAGES_ORIGIN           allowed origin (default: https://thisismattmiller.github.io)
set -euo pipefail

: "${R2_S3_API:?set R2_S3_API to the R2 S3 endpoint URL}"
: "${R2_ACCESS_KEY_ID:?set R2_ACCESS_KEY_ID (from Cloudflare R2 API token)}"
: "${R2_SECRET_ACCESS_KEY:?set R2_SECRET_ACCESS_KEY (from Cloudflare R2 API token)}"
BUCKET="${R2_BUCKET:-embedded-catalog-viz}"
ORIGIN="${PAGES_ORIGIN:-https://thisismattmiller.github.io}"

export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION=auto
# R2 predates the aws-cli v2 flexible-checksum defaults; keep them opt-in
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required

if aws s3api head-bucket --bucket "$BUCKET" --endpoint-url "$R2_S3_API" 2>/dev/null; then
  echo "bucket $BUCKET exists"
else
  echo "creating bucket $BUCKET"
  aws s3api create-bucket --bucket "$BUCKET" --endpoint-url "$R2_S3_API" ||
    { echo "create failed — if your API token is scoped to one bucket, create"
      echo "'$BUCKET' in the Cloudflare dashboard first, then re-run."; exit 1; }
fi

aws s3api put-bucket-cors --bucket "$BUCKET" --endpoint-url "$R2_S3_API" \
  --cors-configuration '{
    "CORSRules": [{
      "AllowedOrigins": ["'"$ORIGIN"'", "http://localhost:8000"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 86400
    }]
  }'
echo "CORS set for $ORIGIN (+ http://localhost:8000)"
echo
echo "REMAINING MANUAL STEP (Cloudflare dashboard -> R2 -> $BUCKET -> Settings):"
echo "  enable public access (r2.dev development URL, or attach a custom domain)"
echo "  then put that public host into site/config.js"
