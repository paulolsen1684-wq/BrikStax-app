// lib/modules/avatar/services/hidden_theme_service.dart
// Evaluates hidden-theme progress against the collection, grants reward
// cosmetics when a tier completes, and persists which tiers are claimed.
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../providers/collection.dart';
import '../../../services/verified.dart';
import '../data/hidden_themes.dart';
import 'achievement_service.dart';
import 'loot_service.dart';

/// Live progress snapshot for one theme.
class ThemeProgress {
  final HiddenTheme theme;
  final int matchedAny;       // count of any matching sets
  final int matchedVerified;  // count of verified matching sets
  final int claimedTiers;     // how many tiers already claimed
  const ThemeProgress({
    required this.theme,
    required this.matchedAny,
    required this.matchedVerified,
    required this.claimedTiers,
  });

  /// The next unclaimed tier, or null if all claimed.
  HiddenThemeTier? get nextTier =>
      claimedTiers < theme.tiers.length ? theme.tiers[claimedTiers] : null;

  /// Current count relevant to the next tier (verified or any).
  int get currentForNext {
    final t = nextTier;
    if (t == null) return 0;
    return t.verifiedOnly ? matchedVerified : matchedAny;
  }

  /// Sets remaining to complete the next tier (>=0).
  int get remainingForNext {
    final t = nextTier;
    if (t == null) return 0;
    final r = t.required - currentForNext;
    return r < 0 ? 0 : r;
  }

  bool get isComplete => claimedTiers >= theme.tiers.length;

  /// 0.0–1.0 toward the next tier.
  double get nextProgress {
    final t = nextTier;
    if (t == null) return 1.0;
    if (t.required == 0) return 1.0;
    final c = currentForNext / t.required;
    return c > 1.0 ? 1.0 : c;
  }
}

class HiddenThemeService {
  HiddenThemeService._();
  static final instance = HiddenThemeService._();

  Database? _db;
  // themeId -> number of tiers claimed
  final Map<String, int> _claimed = {};

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_themes.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE theme_claims (
          id   INTEGER PRIMARY KEY DEFAULT 1,
          data TEXT NOT NULL
        )
      ''');
    });
  }

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> init() async {
    try {
      final db   = await _database;
      final rows = await db.query('theme_claims', where: 'id = 1');
      if (rows.isNotEmpty) {
        final data = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
        _claimed.clear();
        data.forEach((k, v) => _claimed[k] = v as int);
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final db = await _database;
      await db.insert('theme_claims',
          {'id': 1, 'data': jsonEncode(_claimed)},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  int claimedTiers(String themeId) => _claimed[themeId] ?? 0;

  /// Build a progress snapshot for every theme.
  List<ThemeProgress> progressFor(CollectionProvider col) {
    return HiddenThemes.all.map((theme) {
      final any = col.sets.anyThemeCount(theme.needles);
      final ver = col.sets.verifiedThemeCount(theme.needles);
      return ThemeProgress(
        theme: theme,
        matchedAny: any,
        matchedVerified: ver,
        claimedTiers: claimedTiers(theme.id),
      );
    }).toList();
  }

  /// Checks all themes; for any tier now satisfied but not yet claimed, grants
  /// the reward cosmetic and marks it claimed. Returns the list of newly
  /// completed (theme, tier) pairs for celebration UI.
  Future<List<({HiddenTheme theme, HiddenThemeTier tier})>> checkAndGrant(
      CollectionProvider col) async {
    final newly = <({HiddenTheme theme, HiddenThemeTier tier})>[];
    final svc = AchievementService.instance;
    final state = svc.state;
    final unlockedIds = Set<String>.from(state.unlockedIds);
    var changed = false;
    var earned = 0;

    for (final theme in HiddenThemes.all) {
      final any = col.sets.anyThemeCount(theme.needles);
      final ver = col.sets.verifiedThemeCount(theme.needles);
      var claimed = claimedTiers(theme.id);

      // Walk unclaimed tiers in order; stop at the first not yet satisfied.
      while (claimed < theme.tiers.length) {
        final tier = theme.tiers[claimed];
        final have = tier.verifiedOnly ? ver : any;
        if (have < tier.required) break;

        // Tier satisfied — grant reward + advance. A reward already owned
        // (reused across tiers/bundles, see hidden_themes.dart's header
        // comment) pays out Briks instead, same as any other dupe.
        earned += LootService.instance.unlockOrDupePayout(tier.rewardCosmetic, unlockedIds);
        changed = true;
        claimed++;
        _claimed[theme.id] = claimed;
        newly.add((theme: theme, tier: tier));
      }
    }

    if (changed) {
      await svc.updateState(state.copyWith(unlockedIds: unlockedIds));
      await _save();
    }
    if (earned > 0) await LootService.instance.addBriks(earned);
    return newly;
  }

  // DEV ONLY — reset all theme claims
  Future<void> debugReset() async {
    _claimed.clear();
    await _save();
  }
}
