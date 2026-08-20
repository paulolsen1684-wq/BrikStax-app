# lego-rewards-watcher/

A separate, personal Cloudflare Worker (not part of the BrikStax app or
`brikstax-worker`) that monitors LEGO Insiders Rewards for new/changed/
leaving-soon items and alerts the developer via email, Discord, ntfy, and
(dev-gated) push through `brikstax-worker`. See the main `CLAUDE.md`'s
"Push notifications" section for the full history of how the two workers
are connected (`PushService.topicDevAlerts`, etc.).

**Before this folder existed, this worker had no repo anywhere at all** —
not even the dashboard-paste-only situation `brikstax-worker` was in
before `cloudflare-worker/` existed (that one at least had *config*
reconstructable via a working `/content` API pull at the time). This
folder exists so `wrangler deploy` can be run directly without silently
dropping the KV binding, service binding, plaintext vars, or the cron
trigger the live worker actually has.

## ⚠️ `worker.js` here is a placeholder, not the real source

`wrangler.toml` was reconstructed 2026-08-20 from the live worker's real
config via the Cloudflare API (`.../workers/scripts/lego-rewards-watcher
/settings`, `.../schedules`) and validated with `wrangler deploy --dry-run`
— bindings resolved exactly as expected (`REWARDS_KV`, the `BRIKSTAX_WORKER`
service binding, `ALERT_EMAIL`/`LEGO_SECTION_ID`/`NTFY_TOPIC`).

The actual `worker.js` **content** could not be pulled the same way
`cloudflare-worker/worker.js` was — Cloudflare's
`.../workers/scripts/{name}/content` endpoint rejected the OAuth token
`wrangler` itself authenticates with ("Method not allowed for this
authentication scheme", confirmed reproducible across multiple attempts
and header variations), even though that identical token works fine for
`/settings` and `/schedules`. Whatever credential successfully pulled
`brikstax-worker`'s content originally must have been a real
dashboard-issued API Token (Workers Scripts:Edit scope), not an OAuth
session token — none was available when this folder was created.

**Until the real source is pasted in** (Cloudflare dashboard → Workers &
Pages → `lego-rewards-watcher` → Edit Code / Quick Edit → copy the full
file → paste over the placeholder `worker.js` here), **do not run
`wrangler deploy` from this folder** — it would overwrite the live
worker's real `scheduled()`/`fetch()` logic with the placeholder stub.

## Deploying (once real source is in place)

```
cd lego-rewards-watcher
wrangler deploy
```

Requires `wrangler login` once per machine (or an existing cached OAuth
token — check with `wrangler whoami`). Secrets are **not** in
`wrangler.toml` (Cloudflare's API only ever returns secret *names*, never
values) — they're already live on the worker and `wrangler deploy` leaves
existing secrets untouched:

`BRIKSTAX_PUSH_SECRET`, `DISCORD_WEBHOOK_URL`, `LEGO_AUTHORIZATION`,
`LEGO_COOKIE`, `LEGO_FFF_ID`, `LEGO_SESSION_COOKIE_ID`, `LEGO_VISITOR_GUID`,
`MANUAL_TRIGGER_KEY`, `RESEND_API_KEY`, `SYNC_KEY`.

## Known live behavior (2026-08-20 investigation)

Confirmed via `wrangler tail` and the `REWARDS_KV` namespace's stored
state, ahead of finding/fixing the actual "leaving soon" bug this
investigation started from:

- **Cron**: `*/15 * * * *` (every 15 min), confirmed live.
- **A second, independent trigger exists**: an HTTP GET to
  `https://lego-rewards-watcher.paul-olsen1684.workers.dev/?key=<MANUAL_TRIGGER_KEY value>`
  fires roughly in sync with the cron (observed ~4 seconds apart in a live
  tail), believed to be a status-page/uptime monitor. If the `fetch`
  handler runs the *same* full check-and-alert logic as `scheduled()`
  (not yet confirmed without seeing the source), this doubles how often
  alert logic runs, independent of the Cron Trigger.
- **`REWARDS_KV` keys**: `rewards_snapshot` (current state of every reward
  item — `title`/`pointValue`/`quantity`/`type`/`category`/`endDate`/etc.,
  no explicit "leaving soon" field), `rewards_changes_history` (a log of
  past detected changes — **only ever contains `"kind":"added"` and
  `"kind":"changed"` entries, never a `"leaving_soon"` kind**), and
  `session_override`.
- **Working theory, not yet confirmed against real source**: "Leaving
  Soon" status is likely computed fresh every run directly from each
  item's `endDate` (e.g. "within N days of now"), rather than being
  tracked as a discrete state-change event the way `added`/`changed` are.
  If so, and if there's no separate "already alerted about this item's
  leaving-soon status" tracking, every trigger (cron *and* the external
  GET, roughly every 7-8 minutes combined) would re-alert on the same
  still-leaving-soon items indefinitely — matching the reported symptom
  of an email every ~15 minutes. Needs confirming against the real source
  once it's in place here.
- **Push notifications not arriving for leaving-soon alerts specifically**
  is a separate, still-open symptom — not explained by `DevMode` being
  off (confirmed on) or by anything found in this investigation so far.
  Needs the real source to diagnose properly.
