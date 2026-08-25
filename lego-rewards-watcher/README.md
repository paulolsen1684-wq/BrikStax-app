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

## `worker.js` — real source, pasted in 2026-08-20, two bugs fixed

The actual `worker.js` **content** could not be pulled via the Cloudflare
API the way `cloudflare-worker/worker.js` was — the
`.../workers/scripts/{name}/content` endpoint rejects the OAuth token
`wrangler` authenticates with ("Method not allowed for this authentication
scheme", confirmed reproducible across multiple attempts, header variations,
*and* wrangler versions — also tried `wrangler versions download`, which
doesn't exist as a subcommand in any wrangler release checked), even though
that identical token works fine for `/settings`, `/schedules`, and
`versions list`/`view`. Whatever credential successfully pulled
`brikstax-worker`'s content originally must have been a real
dashboard-issued API Token (Workers Scripts:Edit scope), not an OAuth
session token — none was available this session either. Resolved instead by
the user pasting the file directly from the dashboard's Quick Edit view.

**Two real bugs found once the real source was readable, both fixed in this
file (not yet deployed — see Deploying below):**

1. **"Leaving soon" alerts repeated indefinitely, not just occasionally.**
   `wasExpirationAlerted` is a one-off bookkeeping flag with no backing in
   LEGO's API — it only ever gets written onto `current` for items in
   *that specific run's* `expiringItems` list. Since an already-alerted item
   is (correctly) excluded from `expiringItems` on the next run, nothing
   ever re-set the flag on the following run's freshly-rebuilt `current`
   before it was saved — so the flag silently vanished from the snapshot
   after exactly one cycle. Next run reads a flagless snapshot and alerts
   again. Traced cycle-by-cycle this is a deterministic
   alert → skip → alert → skip pattern for as long as an item stays in the
   7-day window, not a probabilistic one. Fixed by carrying
   `wasExpirationAlerted` forward from `previous` into `current` for every
   run, unconditionally, right after `previous` is loaded — not just
   setting it fresh for the current run's own `expiringItems`. Known,
   accepted limitation of the fix (matches the flag's original evident
   intent, not a new gap): it doesn't reset if an item's `endDate` changes
   later (e.g. LEGO extends or relists it) — the original code never
   handled that case either, and it's out of scope for the repeat-alert bug.
2. **A second trigger was running the full alert pipeline, not a status
   check.** `wrangler tail` showed an external `GET /?key=<trigger key>`
   firing roughly in sync with the `*/15 * * * *` cron (believed to be an
   uptime/status monitor). That path fell through to the same
   `runCheck(env)` the cron calls — a full LEGO fetch + diff + alert run —
   instead of the cheap, side-effect-free `/status` view that already
   exists for this exact purpose. Combined with bug 1, this roughly doubled
   the effective alert-check cadence and compounded the flag-dropping
   pattern into something close to "an alert almost every cycle." Fixed:
   that fallback now returns a lightweight liveness JSON response instead
   of invoking `runCheck()`. The real manual "run it now" path is still
   `POST /trigger` (what `/status`'s own Refresh button already uses),
   unaffected by this change.

**Push notifications not arriving was investigated and is _not_ a bug in
this file.** `sendBrikStaxPush`'s header (`x-brikstax-push-secret`) matches
what `brikstax-worker`'s `/push/send` checks (`env.PUSH_SEND_SECRET`,
confirmed by reading that handler directly), both secrets exist on their
respective workers, and the call goes through the `BRIKSTAX_WORKER` service
binding correctly. If the secret values didn't actually match,
`sendBrikStaxPush` would return `ok:false` and `runCheck` would post a
"⚠️ ... BrikStax push failed" line to Discord on every run — worth checking
whether that's ever actually shown up. If it hasn't, the send is very
likely succeeding server-side and the real gap is on the BrikStax app side:
a device only receives `dev_alerts`-topic pushes when both `DevMode` is on
*and* the user has opted into push notifications (see `CLAUDE.md`'s "Push
notifications" section) — nothing to fix here for that.

## Deploying

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
