# embedded-catalog-viz — deployment

Static hosting for the LC catalog embedding map: the HTML pages deploy to
**GitHub Pages** via Actions; the heavy assets (~6 GB: map tiles, click-lookup
shards, timelapse frames, atlas cell shards) live in a **Cloudflare R2** bucket
under a `data/` prefix and are fetched cross-origin by the pages.

```
site/                      what GitHub Pages serves
  index.html               the map viewer        (copied from the dev repo)
  timelapse.html           the timelapse explorer (copied from the dev repo)
  atlas.html               Wikipedia × LC gap atlas (from embedded-catalog-wiki-embeddings)
  config.js                deploy-only: window.DATA_BASE -> public R2 URL
.github/workflows/deploy.yml   Pages deploy on every push to main
scripts/
  sync_site.sh             re-copy viewer pages from ~/git/embedded-catalog-viz
  r2_setup.sh              one-time: create bucket + CORS
  r2_sync.sh               rclone sync of tiles/lookup/timelapse_web/atlas_cells/JSONs to R2
```

`atlas.html` is a self-contained page (its own inline JS/CSS + cell summaries);
on click it fetches one per-cell shard, `data/atlas_cells/<cell>.json` (up to
1,000 LC + 1,000 Wikipedia titles), from R2 via the same `window.DATA_BASE`.
The ~4,075 shards (~260 MB) are staged from the source project into the R2
data dir; regenerate them there with
`embedded-catalog-wiki-embeddings/scripts/build_atlas.py`.

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
- **Atlas changed:** rebuild in the source project
  (`build_atlas.py` → `reports/atlas_cells/`, `build_atlas_viz.py` →
  `reports/atlas.html`), then copy `reports/atlas.html` → `site/atlas.html`,
  mirror `reports/atlas_cells/` → `~/Data/embedded-catalog-viz/atlas_cells/`,
  run `scripts/r2_sync.sh`, commit and push.
