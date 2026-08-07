// lib/services/verified.dart
// Verified-inventory logic. Until the barcode scanner is live, every set counts
// as verified (kScannerLive = false → newly added sets default verified=true via
// the model). The DAY the scanner ships:
//   1. set kScannerLive = true here
//   2. in addSet, pass verified: false for manual entries (scan path passes true)
// Existing sets stay verified (their stored flag is true); only new manual
// entries become unverified. No data migration needed.
import '../models/lego_set.dart';

/// Master switch. Flipped true 2026-08-07 -- barcode DB well past the ~500
/// seeded threshold (2,991+ as of the last check) and FEATURE_SCANNER is
/// live server-side. Scheduled for the next app build/store submission,
/// not a remote flag like FEATURE_SCANNER -- this is compiled in.
const bool kScannerLive = true;

/// Whether a brand-new MANUAL entry should be considered verified.
/// Before the scanner is live, manual entries are trusted (true).
/// After, only scanned sets are verified, so manual = false.
bool get manualEntryDefaultVerified => !kScannerLive;

extension VerifiedCounts on Iterable<LegoSet> {
  /// Count of verified sets (respecting qty).
  int get verifiedCount =>
      where((s) => s.verified).fold(0, (sum, s) => sum + s.qty);

  /// Count of unverified sets (respecting qty).
  int get unverifiedCount =>
      where((s) => !s.verified).fold(0, (sum, s) => sum + s.qty);

  /// Verified sets matching any of the given theme/subtheme substrings.
  int verifiedThemeCount(List<String> needles) => where((s) {
        if (!s.verified) return false;
        final t  = (s.theme ?? '').toLowerCase();
        final st = (s.subtheme ?? '').toLowerCase();
        return needles.any((n) => t.contains(n) || st.contains(n));
      }).fold(0, (sum, s) => sum + s.qty);

  /// All sets matching themes (verified OR not) — for lower difficulty tiers
  /// that don't require verification.
  int anyThemeCount(List<String> needles) => where((s) {
        final t  = (s.theme ?? '').toLowerCase();
        final st = (s.subtheme ?? '').toLowerCase();
        return needles.any((n) => t.contains(n) || st.contains(n));
      }).fold(0, (sum, s) => sum + s.qty);
}
