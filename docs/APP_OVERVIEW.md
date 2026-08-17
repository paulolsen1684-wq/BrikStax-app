# BrikStax — What It Is and What It Does

> **Document status:** describes BrikStax as of **v2.3.0+9** (submitted to the App Store and Play Store 2026-08-17). If you're reading this significantly later, treat feature availability as a snapshot, not a guarantee — check `CLAUDE.md`'s dated changelog for anything added since.

> **Quick facts:** LEGO collection tracker + market-value/companion app · iOS and Android (Flutter app + Cloudflare Worker backend) · free, no ads, no subscriptions, no in-app purchases · monetized only through Amazon/eBay affiliate links · no login or account — identity is an anonymous per-device ID · in-app currency ("Briks") is earned through play only, never purchased.

**BrikStax** is a mobile companion app for LEGO collectors and investors — part collection tracker, part price/market intelligence tool, part gamified hobby app. It runs on iOS and Android (built in Flutter), backed by a Cloudflare Worker server for anything that needs to be shared across users, cached, or kept off-device (pricing data, deals, community moderation, crowdsourced barcode data).

The core idea: most LEGO tracking today is either a spreadsheet or a barcode scanner with no context. BrikStax combines "what do I own" with "what is it worth, is it about to retire, and where can I buy what I don't have yet" — then wraps that in a lightweight avatar/rewards layer so checking in feels like more than data entry.

This document describes the app at the product/feature level for anyone (or any AI) that needs to understand what BrikStax does without reading engineering history. For implementation details, architecture, and the dated changelog of how features were built, see `CLAUDE.md` instead — that file is written for whoever (human or AI) is actively modifying the codebase; this one is written for whoever just needs to know what the app *does*. A glossary of BrikStax-specific terms is at the bottom — check there first if a term used elsewhere (a support message, a screenshot, a review) is unfamiliar.

---

## 1. Collection Tracking (the core)

- Add LEGO sets to a personal collection by **typing a set number**, **scanning a barcode** with the camera, or **bulk-importing** an entire collection from a Rebrickable account.
- Every set is enriched automatically with official data (name, piece count, image, theme/sub-line, release info) pulled from Rebrickable.
- Each set is tracked as **sealed** or **open** — these are genuinely separate, parallel records (separate price histories, separate "have we even checked pricing" flags), not just a status label, because a sealed and opened copy of the same set are different products on the resale market.
- **Verified vs. unverified**: a set added by scanning a real barcode is marked "verified" (higher trust — a real physical scan happened); a set typed in by hand is "unverified." This distinction feeds into some of the collection-based rewards (see Achievements below), rewarding people for actually scanning their shelf rather than guessing at numbers.
- Full backup/restore via JSON export/import.
- A dashboard gives an at-a-glance hierarchy: **today's stuff to do**, **your collection's health/value**, and **things to discover** — rather than one flat scrolling list of cards.

## 2. Pricing & Market Data

- **Retail price** and **barcode/UPC/EAN** lookup via BrickSet.
- **Resale market value** via eBay sold-listing averages, tracked separately for sealed and open condition. This data is fetched server-side and cached for a week, shared across all users of the app (so the cost of asking eBay is paid once, not once per user).
- **Retirement window detection**: sets that are 18–24 months from their retail run ending get flagged as being in the typical "price climb" period collectors watch for.
- **Portfolio value**: the dashboard's headline number is total collection market value, shown with a trend delta and a sparkline — this is the single "how am I doing" number the app is built around.
- **Cost-per-piece** math for evaluating whether a set is a good buy.

## 3. Discovery & Research Tools

These work on **any** set, not just ones you own:

- **Set Lookup** — type any set number and see its pieces, retail price, cost-per-piece, current eBay sealed/open pricing, and retirement status. If you already own it, it links into your collection entry instead of "add to collection."
- **Parts Checker** — pull a set's complete piece list and check off which individual pieces you physically have. Useful for figuring out what's missing after a set gets scattered in a bin, or verifying a secondhand "complete" set actually is. Progress is saved automatically per set number, with no limit on how many sets you're tracking at once, and it doesn't matter whether you check it from the dashboard or from an owned set's own page — it's the same saved progress either way.
- **Parts Merger** (in the Tools/Settings area) — combine the piece lists of **up to 20 official LEGO sets** into one merged shopping list, with matching parts/colors summed rather than duplicated. Exports as a **BrickLink Wanted List XML file** that imports directly into BrickLink for bulk purchasing — this is a real, verified-working import format, not just a spreadsheet you have to manually re-enter. (A separate, more full-featured web version of this tool also supports custom/MOC builds via CSV upload and a plain reference-CSV export; the in-app version is intentionally scoped narrower — official sets only, XML only.)

## 4. Wishlist & Shopping

- Save sets you want to a wishlist, with price tracking.
- Each wishlist card has **"Buy Now" links** straight to Amazon and eBay:
  - Amazon opens a tagged search-results page for that set (Amazon has no public way to link a specific product without a qualifying sales history on their Product Advertising API, so this stays a search link for now).
  - eBay tries to link **directly to a real, currently-listed, new-condition, Buy-It-Now item** for that set via eBay's official product-search API; if nothing matches, it falls back to a tagged eBay search page instead.
- Both links carry the app's own affiliate/referral tags, so purchases made through them earn a commission that supports the app — this is the app's monetization model (affiliate links, not ads or a paywall).

## 5. Deals

- **Deal of the Day**: always the most recently posted live deal (sourced from a moderator Discord bot posting curated LEGO deals — sets, sales, promos).
- **Deal History**: browse the full list of currently-live deals, not just the single featured one.
- Deals also get discovered semi-automatically: the backend polls a deals RSS feed (Slickdeals) for LEGO-related posts and surfaces candidates to a human moderator to approve before they go live — nothing posts fully automatically, a person always confirms the price/link first.

## 6. Avatar & "Brick Den" (the gamification layer)

- Every user has a customizable **pixel-art avatar** built from five slots: head, hat, torso, legs, and a held item — plus a separate background/scene setting.
- Roughly 100 cosmetic items exist across rarity tiers (from common up to legendary animated sets), earned through achievements, daily play, or random reward rolls — not purchased with real money.
- The **Brick Den** is a personal "room" scene showing off the avatar, a trophy shelf, earned badges, and a showcase of your three most valuable owned sets. It can be shared as an image, and it also powers a home-screen widget showing a snapshot of the room.
- A small number of items are **secret/hidden** — found only through rare bonus reward rolls, not visible in the normal unlock list, meant as a surprise for engaged users.

## 7. Daily Engagement

- **Daily Brick claim**: a once-a-day currency claim with a streak counter (currency = "Briks," the app's internal reward point, used only to unlock/duplicate-compensate cosmetics — not real money and not spendable outside the avatar system).
- **Daily Five**: five small daily check-in tasks. Completing them can trigger an opt-in local reminder notification later in the day if you haven't finished, with a small bonus reward tied specifically to days that reminder actually fired.
- **Achievements**: unlocked by collection milestones — owning a certain number of sets, completing certain themes, etc. — each rewarding a cosmetic or currency.
- **Hidden Themes**: a secondary, semi-secret achievement track tied to collecting specific LEGO theme lines, with unlock tiers that additionally reward more for *verified* (barcode-scanned) sets than manually-entered ones.

## 8. Community

- A **photo feed** where users share pictures of their builds/collections.
- Submitted photos go through moderation before appearing publicly — a moderator reviews and approves/rejects via Discord, not an automated filter.
- Posts can be **liked**; when your post gets liked, you earn Briks (claimed automatically when you open the Community tab).
- To prevent spam, there's a cooldown between submissions and a one-like-per-person-per-post rule — enforced via an anonymous per-install device identity rather than requiring an account/login.

## 9. Barcode Scanning

- A real camera-based barcode scanner for adding sets by scanning the box.
- Behind the scenes, the app is backed by a continuously-growing crowdsourced barcode database: when multiple different users scan the same barcode and agree it maps to the same set, that mapping becomes trusted. The database is also proactively expanded in the background using official LEGO catalog data, independent of what users scan.

## 10. Notifications

- **Local, on-device reminders** for the Daily Five task list (opt-in, no server round-trip).
- **Push notifications** infrastructure exists (Firebase-based) but is currently only active for internal testing — not yet turned on for the general user base. When it is, it'll support both broadcast announcements and per-user targeted alerts (e.g., a wishlist item hitting a price target).

## 11. Home Screen Widgets (Android)

Widgets for: total collection value, a random highlighted set from your collection, a quick shortcut into Set Lookup, and a live snapshot of your Brick Den scene.

## 12. Account Model

**No login/account system.** Everything is tied to the device via a locally-generated anonymous identifier. Data lives on-device (with manual JSON export/import as the backup mechanism); only things that are inherently shared (pricing cache, deals, community posts, barcode consensus) live server-side, and none of it is tied to a personal identity.

## 13. Companion Website

A handful of the app's tools also exist as a standalone website (separate from the app, no install required): a landing page, and web versions of the Parts Checker and Parts Merger tools (the web Parts Merger additionally supports custom/MOC builds, which the app version deliberately doesn't). Same visual brand as the app.

---

## Glossary

Terms specific to BrikStax that don't mean what they might elsewhere:

| Term | Meaning |
|---|---|
| **Brik(s)** | The app's internal reward currency. Earned only through play (achievements, daily claims, community likes) — never bought with real money. Spent only on unlocking/duplicate-compensating avatar cosmetics. Has no value or use outside the app. |
| **Brick Den** | The personal "room" scene showing off a user's avatar, trophy shelf, badges, and top-3-value set showcase. Also the name of the home-screen widget that snapshots it. |
| **Sealed / Open** | Condition of an owned set — factory-sealed vs. opened/built. Tracked as fully separate data (separate price histories, separate market values), not just a label, since they're different products on the resale market. |
| **Verified / Unverified** | Whether a collection entry was added by scanning a real barcode (verified) or typed in manually (unverified). Verified sets count more toward certain Hidden Theme rewards. |
| **Retirement window** | The 18–24 month period before a set's retail run typically ends, during which resale prices tend to climb — the app flags sets currently in this window. |
| **Daily Brick** | The once-a-day currency claim with a streak counter. |
| **Daily Five** | Five small daily check-in tasks, separate from the Daily Brick claim, with its own optional reminder notification and bonus. |
| **Hidden Theme** | A semi-secret achievement track tied to collecting specific LEGO theme lines (e.g. completing a Star Wars run), separate from ordinary achievements. |
| **Set number** | LEGO's own official set identifier (e.g. `75192`), used throughout the app as the primary way to identify a set — in Set Lookup, Parts Checker, Parts Merger, and the wishlist. |
| **Discover** | The dashboard section housing tools that work on *any* set, owned or not (Set Lookup, Parts Checker) — distinct from "Your Collection," which only covers owned sets. |
| **Tools** | The renamed Settings tab; houses Parts Merger and other utility-style features that don't fit "Discover" or app configuration. |

---

## Good to know if reasoning about the app

- **Not yet live for regular users**: push notifications, direct eBay product links (waiting on developer API credentials), and a couple of feature flags that can be toggled server-side without an app update.
- **Monetization is affiliate-only** — no ads, no subscriptions, no in-app purchases. Everything reward-related (Briks, cosmetics) is earned through play, never bought.
- **Brand voice**: playful but not childish — brick/collector puns are fine, LEGO-official-catalog-accurate language matters (themes, retirement, sealed/open condition are real terms this audience uses and expects to see used correctly).
- **Primary user**: LEGO collectors and casual investors who care about both "what do I have" and "what's it worth" — somewhere between a hobbyist tracker and a lightweight portfolio app.
