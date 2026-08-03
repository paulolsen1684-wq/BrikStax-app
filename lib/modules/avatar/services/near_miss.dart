// lib/modules/avatar/services/near_miss.dart
// The Near-Miss engine. Scans hidden-theme tiers and trophy families for
// situations where the user is a small number of sets/conditions away from a
// reward, and surfaces them as in-app prompts (no push notifications).
import '../../../providers/collection.dart';
import '../data/hidden_themes.dart';
import '../data/sprite_cosmetics.dart' as sprite;
import 'hidden_theme_service.dart';

enum NearMissKind { theme, trophy }

class NearMiss {
  final NearMissKind kind;
  final String  title;       // e.g. "Galactic Archive"
  final String  emoji;
  final int     remaining;   // how many away (1+)
  final String  unit;        // "set", "sets"
  final String  detail;      // e.g. "Gold tier — verified Star Wars sets"
  final String? rewardName;  // cosmetic name, if any
  final double  progress;    // 0..1 toward the goal
  const NearMiss({
    required this.kind,
    required this.title,
    required this.emoji,
    required this.remaining,
    required this.unit,
    required this.detail,
    required this.progress,
    this.rewardName,
  });

  bool get isOneAway => remaining == 1;
}

class NearMissEngine {
  NearMissEngine._();
  static final instance = NearMissEngine._();

  /// Surface prompts when within this many of a goal.
  static const int threshold = 3;

  /// Build the list of active near-misses, closest first.
  List<NearMiss> scan(CollectionProvider col) {
    final out = <NearMiss>[];

    // ── Hidden theme tiers ────────────────────────────────────────────────
    final progress = HiddenThemeService.instance.progressFor(col);
    for (final p in progress) {
      final tier = p.nextTier;
      if (tier == null) continue;             // theme complete
      final remaining = p.remainingForNext;
      if (remaining <= 0 || remaining > threshold) continue;

      // Only surface a theme the user has actually started (avoid spoiling
      // every hidden theme at once).
      if (p.matchedAny == 0) continue;

      final tierName = switch (tier.tier) {
        ThemeTier.bronze  => 'Bronze',
        ThemeTier.silver  => 'Silver',
        ThemeTier.gold    => 'Gold',
        ThemeTier.diamond => 'Diamond',
      };
      final verifiedNote = tier.verifiedOnly ? ' (verified)' : '';
      final rewardName = sprite.spriteCosmeticsById[tier.rewardCosmetic]?.name;

      out.add(NearMiss(
        kind: NearMissKind.theme,
        title: p.theme.name,
        emoji: p.theme.emoji,
        remaining: remaining,
        unit: remaining == 1 ? 'set' : 'sets',
        detail: '$tierName tier$verifiedNote',
        rewardName: rewardName,
        progress: p.nextProgress,
      ));
    }

    // ── Trophy families (count-based milestones) ──────────────────────────
    // These mirror the Den trophy thresholds. We surface the next milestone
    // when the user is within threshold of it.
    final total = col.sets.fold<int>(0, (s, e) => s + e.qty);
    _trophyNearMiss(out, '📦', 'Collection', total,
        const [10, 50, 250], const ['Bronze', 'Silver', 'Gold']);

    final sealed = col.sets
        .where((s) => s.status == 'sealed')
        .fold<int>(0, (s, e) => s + e.qty);
    _trophyNearMiss(out, '🔒', 'Sealed Vault', sealed,
        const [5, 10, 25], const ['Bronze', 'Silver', 'Gold']);

    // Sort: fewest remaining first, then themes before trophies for variety.
    out.sort((a, b) {
      final c = a.remaining.compareTo(b.remaining);
      if (c != 0) return c;
      return a.kind.index.compareTo(b.kind.index);
    });
    return out;
  }

  void _trophyNearMiss(List<NearMiss> out, String emoji, String name,
      int current, List<int> milestones, List<String> labels) {
    for (int i = 0; i < milestones.length; i++) {
      final m = milestones[i];
      if (current >= m) continue;            // already past this one
      final remaining = m - current;
      if (remaining <= 0 || remaining > threshold) return; // too far → stop
      out.add(NearMiss(
        kind: NearMissKind.trophy,
        title: name,
        emoji: emoji,
        remaining: remaining,
        unit: remaining == 1 ? 'set' : 'sets',
        detail: '${labels[i]} trophy at $m',
        progress: current / m,
      ));
      return; // only surface the nearest milestone per family
    }
  }

  /// Convenience: just the single most urgent near-miss, or null.
  NearMiss? top(CollectionProvider col) {
    final list = scan(col);
    return list.isEmpty ? null : list.first;
  }
}
