# embedded-catalog-viz — deployment

Static hosting for the LC catalog embedding map: the two HTML pages deploy to
**GitHub Pages** via Actions; the heavy assets (~5.7 GB: map tiles, click-lookup
shards, timelapse frames) live in a **Cloudflare R2** bucket under a `data/`
prefix and are fetched cross-origin by the pages.

```
site/                      what GitHub Pages serves
  index.html               the map viewer        (copied from the dev repo)
  timelapse.html           the timelapse explorer (copied from the dev repo)
  config.js                deploy-only: window.DATA_BASE -> public R2 URL
.github/workflows/deploy.yml   Pages deploy on every push to main
scripts/
  sync_site.sh             re-copy viewer pages from ~/git/embedded-catalog-viz
  r2_setup.sh              one-time: create bucket + CORS
  r2_sync.sh               rclone sync of tiles/lookup/timelapse_web/JSONs to R2
```

## One-time setup

1. Create an R2 API token (Cloudflare dashboard → R2 → Manage R2 API Tokens,
   permission "Object Read & Write") and export, alongside the existing
   `R2_S3_API` endpoint var:

   ```sh
   export R2_ACCESS_KEY_ID=...      # 32-hex access key from the token
   export R2_SECRET_ACCESS_KEY=...  # secret from the token
   ```

2. `scripts/r2_setup.sh` — creates the `embedded-catalog-viz` bucket and sets
   CORS for the Pages origin.

3. In the Cloudflare dashboard, enable public access on the bucket
   (Settings → r2.dev development URL, or attach a custom domain — a custom
   domain is recommended; r2.dev is rate-limited and a busy map view requests
   dozens of tiles at once).

4. Put the public host in `site/config.js`:
   `window.DATA_BASE = "https://pub-….r2.dev/data"`.

5. Push to `main`. The workflow enables Pages automatically; the site lands at
   <https://thisismattmiller.github.io/embedded-catalog-viz/>.

## Updating

- **New render (tiles/labels/lookup changed):** `scripts/r2_sync.sh`
  (idempotent; only changed files upload).
- **Viewer code changed:** `scripts/sync_site.sh`, then commit and push.
