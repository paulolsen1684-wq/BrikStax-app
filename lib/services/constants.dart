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

  // Cloudflare Worker — handles BrickSet proxy AND eBay with D1 cache
  // eBay calls go to: POST ${workerUrl}ebay
  // BrickSet/proxy:   GET  ${workerUrl}?url=...
  static const workerUrl = 'https://brikstax-worker.paul-olsen1684.workers.dev/';

  // Business rules
  static const insiderPointsRate    = 0.05;   // 5% LEGO Insider
  static const ebayStaleAfterDays   = 7;       // re-fetch after 7 days
  static const rbThemeCacheTtlDays  = 30;      // theme names rarely change
  static const priceHistoryMaxPoints= 52;      // ~1 year of weekly fetches

  // Storage keys
  static const dbName       = 'brickledger.db';
  static const prefEbayQuota= 'ebay_quota_v1';
  static const prefTheme    = 'app_theme_v1';
  static const prefRbToken  = 'rb_user_token';
}
