// lib/services/constants.dart
// Single source of truth for all API keys and config.
// NOTE: eBay key is now stored in the Cloudflare Worker as an
// encrypted environment variable — it is NOT in the app code.

class K {
  K._();

  // Rebrickable
  static const rbKey = 'b42853a0b20a0be42e774e2ab88fa739';

  // BrickSet (low-sensitivity, public API key)
  static const bsKey = '3-Dwg8-SY9s-4VdM8';

  // Affiliate tags -- public, non-secret identifiers meant to appear
  // directly in a URL (unlike an API key), same as an Amazon Associates
  // tag or eBay Partner Network campaign id always is. Match the exact
  // values the Cloudflare Worker uses for Discord-posted deals (see
  // AMAZON_TAG/EBAY_CAMPAIGN_ID in cloudflare-worker/worker.js) so every
  // BrikStax-sourced link, app or Discord, credits the same account.
  static const amazonTag = 'brikstax-20';
  static const ebayCampaignId = '5339171029';

  // Cloudflare Worker — handles BrickSet proxy AND eBay with D1 cache
  // eBay calls go to: POST ${workerUrl}ebay
  // BrickSet/proxy:   GET  ${workerUrl}?url=...
  static const workerUrl = 'https://brikstax-worker.paul-olsen1684.workers.dev/';

  // Business rules
  static const insiderPointsRate    = 0.05;   // 5% LEGO Insider
  static const ebayStaleAfterDays   = 7;       // re-fetch after 7 days
  // Minifig values (BrickEconomy) get a much longer TTL than eBay's -- the
  // shared server-side budget is only 100 requests/day across every install
  // (see brikstax-worker's BRICKECONOMY_DAILY_CAP), so this is a client-side
  // staleness *indicator* only, never an auto-refresh trigger. A stale badge
  // just means "tap Check current value if you want a fresher number,"
  // exactly the opposite of eBay's staleness driving an automatic refresh.
  static const minifigValueStaleAfterDays = 30;
  static const rbThemeCacheTtlDays  = 30;      // theme names rarely change
  static const priceHistoryMaxPoints= 52;      // ~1 year of weekly fetches

  // Storage keys
  static const dbName       = 'brickledger.db';
  static const prefEbayQuota= 'ebay_quota_v1';
  static const prefTheme    = 'app_theme_v1';
  static const prefRbToken  = 'rb_user_token';
}
