# cloudflare-worker/

Deploy config + a working copy of the `brikstax-worker` Cloudflare Worker
(the backend the Flutter app talks to via `K.workerUrl` — eBay price proxy,
BrickSet proxy, Community feed/moderation, barcode consensus, deals,
push send, etc.). Added 2026-08-11.

**Before this existed there was no `wrangler.toml` anywhere** — the worker
had only ever been maintained by pasting a full `worker.js` by hand into
the Cloudflare dashboard's inline editor (see the main `CLAUDE.md`'s
"External APIs" section). `wrangler.toml` here was reconstructed from the
live worker's actual settings via the Cloudflare API (bindings, D1/R2,
cron schedules, subdomain config), then validated with
`wrangler deploy --dry-run` — bindings resolved exactly as expected.

## Deploying

```
cd cloudflare-worker
wrangler deploy
```

Requires `wrangler login` once per machine (or an existing cached OAuth
token — check with `wrangler whoami`). Secrets are **not** in
`wrangler.toml` — Cloudflare's API only ever returns secret *names*, never
values, so they can't be reconstructed this way. They're already live on
the worker and `wrangler deploy` leaves existing secrets untouched, so
this works as-is for redeploying code/config changes. They'd only need
re-entering (`wrangler secret put <NAME>`) if this worker were ever
recreated from scratch:

`BRICKSET_KEY`, `DISCORD_BOT_TOKEN`, `DISCORD_PUBLIC_KEY`, `EBAY_KEY`,
`FIREBASE_SERVICE_ACCOUNT_JSON`, `MOD_CHANNEL_ID`, `MOD_WEBHOOK_URL`,
`NEWS_SECRET`, `PUSH_SEND_SECRET`, `RB_KEY`, `RB_KEY2`, `RB_KEY3`.

## ⚠️ `worker.js` here is the deployed *bundle*, not the authored source

The copy in this folder was pulled straight from the live worker via the
Cloudflare API, and it's missing something important: **none of the
original doc comments survived** (the ones `CLAUDE.md` quotes verbatim,
e.g. the `DEAL_CRON` block explaining the Cron Trigger setup). It's
esbuild-bundled output — helper functions, no comments, `qrcode-generator`
inlined from node_modules. It's accurate for *behavior* (safe to redeploy
as-is, confirmed via dry-run) but not useful to read or hand-edit.

The last known copy *with* comments intact predates this file — it's from
before the 2026-08-11 Parts Merger addition (see commit `c6b1103`), so it's
not current either. Until reconciled, treat any future worker.js edit the
same way this project always has: get the authored version (with comments)
from wherever it was last edited/handed over, apply the change there, and
only then either paste it into the dashboard by hand (old way) or drop the
result in here and `wrangler deploy` (new way, now that this config
exists). Don't hand-edit the bundle in this folder directly — the next
real pull from the dashboard would just overwrite it anyway.
