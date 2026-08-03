// lib/modules/avatar/models/loot_roll.dart

enum BrickTier { common, rare, epic }

class LootRoll {
  final String   cosmeticId;
  final BrickTier tier;
  final DateTime rolledAt;
  final bool     wasBundle;

  const LootRoll({
    required this.cosmeticId,
    required this.tier,
    required this.rolledAt,
    this.wasBundle = false,
  });
}

class DailyStreak {
  final int      streak;       // current streak in days
  final int      longest;      // all-time longest streak
  final DateTime? lastClaim;   // when user last claimed
  final bool     canClaim;     // ready to claim today?
  final BrickTier nextTier;   // what tier today's brick is

  const DailyStreak({
    required this.streak,
    required this.longest,
    this.lastClaim,
    required this.canClaim,
    required this.nextTier,
  });

  static DailyStreak get empty => DailyStreak(
    streak:    0,
    longest:   0,
    lastClaim: null,
    canClaim:  true,
    nextTier:  BrickTier.common,
  );

  Map<String, dynamic> toJson() => {
    'streak':    streak,
    'longest':   longest,
    'lastClaim': lastClaim?.toIso8601String(),
    'nextTier':  nextTier.name,
  };

  factory DailyStreak.fromJson(Map<String, dynamic> j) {
    final lastClaim = j['lastClaim'] != null
        ? DateTime.tryParse(j['lastClaim'] as String)
        : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool canClaim = true;
    if (lastClaim != null) {
      final lastDay = DateTime(lastClaim.year, lastClaim.month, lastClaim.day);
      canClaim = lastDay.isBefore(today);
    }
    final streak = j['streak'] as int? ?? 0;
    return DailyStreak(
      streak:    streak,
      longest:   j['longest'] as int? ?? 0,
      lastClaim: lastClaim,
      canClaim:  canClaim,
      nextTier:  tierForStreak(streak),
    );
  }

  static BrickTier tierForStreak(int streak) {
    if (streak >= 29) return BrickTier.epic;
    if (streak >= 6)  return BrickTier.rare;
    return BrickTier.common;
  }

  String get tierLabel => switch (nextTier) {
    BrickTier.common => 'Common Brick',
    BrickTier.rare   => 'Rare Brick',
    BrickTier.epic   => 'Epic Brick',
  };

  String get streakMilestoneLabel {
    if (streak < 6)  return '${6  - streak} days to Rare Brick';
    if (streak < 29) return '${29 - streak} days to Epic Brick';
    return 'Max streak! Epic bricks forever';
  }
}
