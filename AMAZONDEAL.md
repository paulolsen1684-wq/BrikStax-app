# `/amazondeal` — Discord command reference

Posts an Amazon deal to BrikStax's deals feed (same feed `/deal` and `/deallink` post to, surfaced in-app via the Dashboard's "Deal of the Day" card and `DealsService`), with your Amazon Associates affiliate tag automatically appended to the URL.

Lives in the Worker (`worker.js`), not this Flutter repo — see [CLAUDE.md](CLAUDE.md)'s "External APIs" section for how it fits into the rest of the Discord command set.

## Why it's manual-entry, not scraped

Every other link-based command (`/newslink`, `/deallink`) fetches the page and scrapes Open Graph tags for title/image. `/amazondeal` deliberately does **not** do this for Amazon links — Amazon's Conditions of Use prohibit automated/programmatic access to their pages, so this command never sends a single request to amazon.com. You type the title, price, and everything else yourself, exactly like `/deal` already works for any other retailer. The only thing the command does automatically is take the URL you paste and append `?tag=brikstax-20` (or overwrite an existing `tag=` param) — pure string manipulation on a link you already have, not scraping.

If real-time Amazon pricing/title/image data is ever wanted without typing it by hand, the compliant path is Amazon's **Product Advertising API** (requires 3 qualifying sales within 180 days to unlock for a new Associates account) — not scraping. Don't reintroduce a scrape-based version of this command.

## Command syntax

```
/amazondeal title:<text> url:<text> [price:<number>] [retail:<number>]
            [set:<text>] [image:<text>] [note:<text>] [featured:<bool>] [days:<int>]
```

| Option | Required | Type | Notes |
|---|---|---|---|
| `title` | Yes | string | Deal title shown in the feed |
| `url` | Yes | string | The Amazon product link. Gets your `tag=brikstax-20` appended automatically, overwriting any existing tag |
| `price` | No | number | Deal price, e.g. `49.99` |
| `retail` | No | number | Retail/MSRP price, e.g. `79.99` — combined with `price`, the feed shows a "% off" badge |
| `set` | No | string | LEGO set number this deal is for |
| `image` | No | string | Image URL — not auto-fetched, paste one manually if you want a thumbnail |
| `note` | No | string | Extra note shown with the deal |
| `featured` | No | bool | Marks it as the featured "Deal of the Day" |
| `days` | No | int | Days until the deal expires (default 30, matching `/deal`'s default) |

## Example

```
/amazondeal title:LEGO Icons Bonsai Tree url:https://www.amazon.com/dp/B08T7T51DR
            price:39.99 retail:49.99 set:10281 featured:true
```

Posts immediately (no deferred/background step, unlike `/deallink`) since there's no fetch involved — response is instant.

## Where it lives in `worker.js`

- `AMAZON_TAG` constant and `buildAmazonAffiliateLink()` helper — near the DEALS section, alongside `handleDealsGet`/`handleDealsAdd`
- Command handler — inside `handleDiscord()`, in the `body.type === 2` (slash command) block, right after the existing `/deal` handler
- Inserts into the same `deals` table as `/deal`/`/deallink`, with `retailer` hardcoded to `'Amazon'`

## One-time setup (already done, here for reference)

Registering the slash command with Discord — only needs to run again if the command definition changes:

```bash
curl -X POST "https://discord.com/api/v10/applications/YOUR_APP_ID/commands" \
  -H "Authorization: Bot YOUR_BOT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "amazondeal",
    "description": "Post an Amazon deal with your affiliate link (same as /deal, auto-tags the URL)",
    "options": [
      { "name": "title",    "description": "Deal title",                          "type": 3,  "required": true },
      { "name": "url",      "description": "Amazon product link",                 "type": 3,  "required": true },
      { "name": "price",    "description": "Deal price, e.g. 49.99",              "type": 10, "required": false },
      { "name": "retail",   "description": "Retail/MSRP price, e.g. 79.99",       "type": 10, "required": false },
      { "name": "set",      "description": "LEGO set number this deal is for",    "type": 3,  "required": false },
      { "name": "image",    "description": "Image URL",                          "type": 3,  "required": false },
      { "name": "note",     "description": "Extra note",                         "type": 3,  "required": false },
      { "name": "featured", "description": "Feature this deal",                  "type": 5,  "required": false },
      { "name": "days",     "description": "Days until expiry (default 30)",     "type": 4,  "required": false }
    ]
  }'
```

## Status

Built and handed off as a complete `worker.js` — deployment (pasting into your live Worker) and Discord command registration not yet confirmed on your end.
