// lib/modules/avatar/services/loot_service.dart
//
// The loot pool is every BackgroundCosmetic (backgrounds) PLUS every
// PixelCosmetic (head/hat/torso/legs/item -- the live figure catalog) minus
// each slot's starter/default item (nobody should "win" the thing they
// already start with) and minus anything reserved for a hidden theme /
// bundle / secret drop. Pixel items joined the pool once the catalog grew
// past a small preview batch and got real rarity data -- see
// PixelRarityX.asCosmeticRarity for how its 4 tiers map onto this file's
// existing 5-tier CosmeticRarity economy rather than needing a second one.
import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../providers/collection.dart';
import '../data/bundles.dart';
import '../data/hidden_themes.dart';
import '../data/pixel_cosmetics.dart' as pixel;
import '../data/background_cosmetics.dart' as bg;
import '../models/avatar_state.dart';
import '../models/bundle.dart';
import '../models/loot_roll.dart';
import 'achievement_service.dart';

/// Result of a claim or purchase: the roll plus any Briks earned.
class ClaimResult {
  final LootRoll roll;
  final int      briksEarned; // includes the +1 daily drip and any dupe payout
  final bool     wasDupe;
  const ClaimResult({
    required this.roll,
    this.briksEarned = 0,
    this.wasDupe = false,
  });
}

/// One rollable reward: an id from either catalog plus its rarity, unified
/// so the roll/pool logic doesn't need to care which catalog it came from.
class _RewardEntry {
  final String id;
  final bg.CosmeticRarity rarity;
  const _RewardEntry(this.id, this.rarity);
}

// Starter items every player begins with -- excluded from the pool, same
// as the old catalog's isDefault flag did. Only the background
// side of the pool uses this; the pixel side below uses
// AvatarState.starterIds instead, which is the figure catalog's starter
// set. 'bg_cream' is the only entry now -- head_01/helmet_38/outfit_34
// (stale ids from the retired figure catalog) were removed 2026-08-12
// along with the rest of that system's leftovers.
const _starterIds = {'bg_cream'};

// isSecret background cosmetics are excluded from the normal pool -- they'd
// otherwise just be an ordinary roll at whatever rarity they're tagged,
// no rarer than any other legendary item. _maybeSecretDrop below is the
// separate, much-lower-odds check that actually reaches them.
//
// Hidden-theme and bundle rewards are excluded too, for the same reason:
// they're meant to be exclusive to completing that theme/bundle, not also
// winnable as an ordinary random roll.
final Set<String> _themeAndBundleIds = {
  for (final theme in HiddenThemes.all)
    for (final tier in theme.tiers) tier.rewardCosmetic,
  for (final bundle in AllBundles.all) ...bundle.cosmeticIds,
};

List<_RewardEntry> get _rewardPool => [
  ...bg.allBackgroundCosmetics
      .where((c) =>
          !_starterIds.contains(c.id) &&
          !c.isSecret &&
          !_themeAndBundleIds.contains(c.id))
      .map((c) => _RewardEntry(c.id, c.rarity)),
  ...pixel.allPixelCosmetics
      .where((c) =>
          !AvatarState.starterIds.contains(c.id) &&
          !c.isSecret &&
          !_themeAndBundleIds.contains(c.id))
      .map((c) => _RewardEntry(c.id, c.rarity.asCosmeticRarity)),
];

class LootService {
  LootService._();
  static final instance = LootService._();

  Database? _db;
  DailyStreak _streak = DailyStreak.empty;
  final Set<String> _unlockedBundles = {};
  int _briks = 0;
  final _rng = Random.secure();

  // `canClaim` is normally only ever recomputed against the current date
  // by DailyStreak.fromJson, called exclusively from init() at cold app
  // start. There's no AppLifecycleState observer anywhere in this app, so
  // nothing rechecks it if the session stays alive across local midnight
  // (backgrounded, not force-quit) -- every one of this getter's 4 call
  // sites (daily_claim_screen, dashboard_avatar_card,
  // DailyFiveService.isDone(checkin), claimDaily's own guard) would keep
  // showing yesterday's "already claimed" state until a full restart.
  // Self-corrects here instead, at the one shared read path, rather than
  // needing every call site to remember an ensureToday()-style call first.
  DailyStreak get streak {
    if (!_streak.canClaim && _streak.lastClaim != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastDay = DateTime(
          _streak.lastClaim!.year, _streak.lastClaim!.month, _streak.lastClaim!.day);
      if (lastDay.isBefore(today)) {
        _streak = DailyStreak(
          streak:    _streak.streak,
          longest:   _streak.longest,
          lastClaim: _streak.lastClaim,
          canClaim:  true,
          nextTier:  _streak.nextTier,
        );
      }
    }
    return _streak;
  }

  Set<String> get unlockedBundles => Set.unmodifiable(_unlockedBundles);
  int get briks => _briks;

  // ── Briks economy table ────────────────────────────────────────────────
  // Dupe payout = full rarity value. Guaranteed roll cost = same number,
  // so 2 dupes of a tier always buy 1 roll of the tier above.
  static int brikValue(bg.CosmeticRarity r) => switch (r) {
    bg.CosmeticRarity.common    => 1,
    bg.CosmeticRarity.uncommon  => 2,
    bg.CosmeticRarity.rare      => 4,
    bg.CosmeticRarity.epic      => 8,
    bg.CosmeticRarity.legendary => 16,
  };

  static int brikCost(bg.CosmeticRarity r) => brikValue(r);

  /// Rarity of any catalog id, background or pixel (figure) -- used
  /// to price dupe payouts for grants that don't go through the normal roll
  /// pool (bundle pieces, hidden-theme rewards).
  bg.CosmeticRarity? rarityOf(String id) =>
      bg.backgroundCosmeticsById[id]?.rarity ??
      pixel.pixelCosmeticsById[id]?.rarity.asCosmeticRarity;

  /// Unlocks [id] into [unlockedIds] if it's new; otherwise returns its
  /// rarity's Brik value as dupe compensation (0 if unlocked but newly
  /// added, or if the id doesn't resolve to a real rarity). Mutates
  /// [unlockedIds] in place -- callers still own persisting the result.
  ///
  /// Shared by every grant path that can hand out an id the player might
  /// already own: claimDaily, grantBonusRoll, equipBundle, unlockBundle
  /// here, and HiddenThemeService.checkAndGrant. All five used to
  /// reimplement this same "already owned? pay Briks : unlock" branch by
  /// hand.
  int unlockOrDupePayout(String id, Set<String> unlockedIds) {
    if (unlockedIds.contains(id)) {
      final r = rarityOf(id);
      return r != null ? brikValue(r) : 0;
    }
    unlockedIds.add(id);
    return 0;
  }

  // ── Secret drops ─────────────────────────────────────────────────────────
  // A flat, independent ~1.5% chance per free/earned roll (daily claim or
  // bonus roll -- NOT the paid guaranteed roll, since buying a specific
  // rarity on demand should never be able to shortcut a surprise). Checked
  // before the normal tier-distribution roll; a hit replaces that roll for
  // this claim rather than stacking an extra grant on top, keeping "one
  // thing per claim" simple. Pulls from every isSecret background cosmetic the
  // player hasn't already unlocked -- add more by tagging new catalog
  // entries isSecret: true, nothing here needs to change.
  static const double _secretDropChance = 0.015;

  String? _maybeSecretDrop() {
    final owned = AchievementService.instance.state.unlockedIds;
    final pool = <String>[
      ...bg.allBackgroundCosmetics
          .where((c) => c.isSecret && !owned.contains(c.id))
          .map((c) => c.id),
      ...pixel.allPixelCosmetics
          .where((c) => c.isSecret && !owned.contains(c.id))
          .map((c) => c.id),
    ];
    if (pool.isEmpty) return null; // every secret already found
    if (_rng.nextDouble() >= _secretDropChance) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  /// How many rewards of [r] the player does NOT yet own.
  int remainingOfRarity(bg.CosmeticRarity r) {
    final owned = AchievementService.instance.state.unlockedIds;
    return _rewardPool
        .where((c) => c.rarity == r && !owned.contains(c.id))
        .length;
  }

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'brikstax_loot.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE loot_state (
            id   INTEGER PRIMARY KEY DEFAULT 1,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bundle_state (
            id   INTEGER PRIMARY KEY DEFAULT 1,
            data TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE wallet (
            id    INTEGER PRIMARY KEY DEFAULT 1,
            briks INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS wallet (
              id    INTEGER PRIMARY KEY DEFAULT 1,
              briks INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> init() async {
    try {
      final db   = await _database;
      final rows = await db.query('loot_state', where: 'id = 1');
      if (rows.isNotEmpty) {
        final data = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
        _streak = DailyStreak.fromJson(data);
      }
      final bRows = await db.query('bundle_state', where: 'id = 1');
      if (bRows.isNotEmpty) {
        final data = jsonDecode(bRows.first['data'] as String) as List;
        _unlockedBundles.addAll(data.cast<String>());
      }
      final wRows = await db.query('wallet', where: 'id = 1');
      if (wRows.isNotEmpty) {
        _briks = wRows.first['briks'] as int;
      }
    } catch (_) {}
  }

  Future<void> _saveStreak() async {
    try {
      final db = await _database;
      await db.insert('loot_state',
          {'id': 1, 'data': jsonEncode(_streak.toJson())},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> _saveBundles() async {
    try {
      final db = await _database;
      await db.insert('bundle_state',
          {'id': 1, 'data': jsonEncode(_unlockedBundles.toList())},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> _saveBriks() async {
    try {
      final db = await _database;
      await db.insert('wallet', {'id': 1, 'briks': _briks},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> addBriks(int n) async {
    _briks += n;
    await _saveBriks();
  }

  /// Returns false (and spends nothing) if the balance is insufficient.
  Future<bool> spendBriks(int n) async {
    if (_briks < n) return false;
    _briks -= n;
    await _saveBriks();
    return true;
  }

  // ── Daily claim ──────────────────────────────────────────────────────────
  Future<ClaimResult?> claimDaily() async {
    if (!_streak.canClaim) return null;

    final now     = DateTime.now();
    final lastDay = _streak.lastClaim != null
        ? DateTime(_streak.lastClaim!.year, _streak.lastClaim!.month, _streak.lastClaim!.day)
        : null;
    final today   = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Determine new streak
    int newStreak;
    if (lastDay == null) {
      newStreak = 1;
    } else if (lastDay == yesterday) {
      newStreak = _streak.streak + 1; // consecutive
    } else {
      newStreak = 1; // broke streak
    }

    // Streak milestone guarantees
    bg.CosmeticRarity? minRarity;
    if (newStreak == 100) {
      minRarity = bg.CosmeticRarity.legendary;
    } else if (newStreak == 30) {
      minRarity = bg.CosmeticRarity.epic;
    } else if (newStreak == 7) {
      minRarity = bg.CosmeticRarity.rare;
    }

    final tier = DailyStreak.tierForStreak(newStreak - 1);
    final roll = _maybeSecretDrop() ?? _rollLoot(tier, minRarity: minRarity);

    _streak = DailyStreak(
      streak:    newStreak,
      longest:   max(newStreak, _streak.longest),
      lastClaim: now,
      canClaim:  false,
      nextTier:  DailyStreak.tierForStreak(newStreak),
    );
    await _saveStreak();

    // Grant the cosmetic — or, if it's a dupe, pay out Briks instead
    final svc     = AchievementService.instance;
    final state   = svc.state;
    final wasDupe = state.unlockedIds.contains(roll);

    final newUnlocked = Set<String>.from(state.unlockedIds);
    final earned = 1 + unlockOrDupePayout(roll, newUnlocked); // daily drip — every claim pays at least 1 Brik
    if (!wasDupe) await svc.updateState(state.copyWith(unlockedIds: newUnlocked));
    await addBriks(earned);

    return ClaimResult(
      roll: LootRoll(
        cosmeticId: roll,
        tier:       tier,
        rolledAt:   now,
      ),
      briksEarned: earned,
      wasDupe:     wasDupe,
    );
  }

  String _rollLoot(BrickTier tier, {bg.CosmeticRarity? minRarity}) {
    final double roll = _rng.nextDouble();

    // Five-tier odds. Each brick tier has its own distribution.
    bg.CosmeticRarity target;
    switch (tier) {
      case BrickTier.epic:
        // 75% legendary / 25% epic
        target = roll < 0.75 ? bg.CosmeticRarity.legendary : bg.CosmeticRarity.epic;
        break;
      case BrickTier.rare:
        // 10% uncommon / 40% rare / 38% epic / 12% legendary
        if (roll < 0.10)      target = bg.CosmeticRarity.uncommon;
        else if (roll < 0.50) target = bg.CosmeticRarity.rare;
        else if (roll < 0.88) target = bg.CosmeticRarity.epic;
        else                  target = bg.CosmeticRarity.legendary;
        break;
      case BrickTier.common:
        // 50% common / 30% uncommon / 14% rare / 5% epic / 1% legendary
        if (roll < 0.50)      target = bg.CosmeticRarity.common;
        else if (roll < 0.80) target = bg.CosmeticRarity.uncommon;
        else if (roll < 0.94) target = bg.CosmeticRarity.rare;
        else if (roll < 0.99) target = bg.CosmeticRarity.epic;
        else                  target = bg.CosmeticRarity.legendary;
    }

    // Apply streak milestone guarantee: never roll below minRarity
    if (minRarity != null && target.index < minRarity.index) {
      target = minRarity;
    }

    // Get rewards of that rarity not yet unlocked
    final state = AchievementService.instance.state;
    final pool  = _rewardPool.where((c) => c.rarity == target).toList();
    final unlocked = pool.where((c) => !state.unlockedIds.contains(c.id)).toList();

    // If all of target rarity are owned, pick any not owned
    final candidates = unlocked.isNotEmpty
        ? unlocked
        : _rewardPool.where((c) => !state.unlockedIds.contains(c.id)).toList();

    // If everything is owned, pick any reward (claimDaily converts to Briks)
    if (candidates.isEmpty) {
      final all = _rewardPool;
      return all[_rng.nextInt(all.length)].id;
    }

    return candidates[_rng.nextInt(candidates.length)].id;
  }

  // ── Brik Shop: buy a guaranteed roll of a chosen rarity ─────────────────
  /// Returns null if balance is insufficient or no unowned items of that
  /// rarity remain. Otherwise spends Briks, grants a random unowned reward
  /// of exactly [rarity], and returns the result for the reveal popup.
  Future<ClaimResult?> buyGuaranteedRoll(bg.CosmeticRarity rarity) async {
    final cost = brikCost(rarity);
    if (_briks < cost) return null;

    final svc   = AchievementService.instance;
    final state = svc.state;
    final pool  = _rewardPool
        .where((c) => c.rarity == rarity && !state.unlockedIds.contains(c.id))
        .toList();
    if (pool.isEmpty) return null;

    final pick = pool[_rng.nextInt(pool.length)];

    final ok = await spendBriks(cost);
    if (!ok) return null;

    final newUnlocked = Set<String>.from(state.unlockedIds)..add(pick.id);
    await svc.updateState(state.copyWith(unlockedIds: newUnlocked));

    return ClaimResult(
      roll: LootRoll(
        cosmeticId: pick.id,
        tier: switch (rarity) {
          bg.CosmeticRarity.common   => BrickTier.common,
          bg.CosmeticRarity.uncommon => BrickTier.common,
          bg.CosmeticRarity.rare     => BrickTier.rare,
          _                            => BrickTier.epic,
        },
        rolledAt: DateTime.now(),
      ),
    );
  }

  // ── Bonus rolls (scanner rewards etc. — wire up when scanner goes live) ──
  /// Grants a free roll, optionally with a rarity floor. First-ever barcode
  /// scan should call this with minRarity: CosmeticRarity.epic; every 10th
  /// scan calls it with no floor.
  Future<ClaimResult?> grantBonusRoll({bg.CosmeticRarity? minRarity}) async {
    final roll = _maybeSecretDrop() ?? _rollLoot(BrickTier.common, minRarity: minRarity);
    final svc     = AchievementService.instance;
    final state   = svc.state;
    final wasDupe = state.unlockedIds.contains(roll);

    final newUnlocked = Set<String>.from(state.unlockedIds);
    final earned = unlockOrDupePayout(roll, newUnlocked);
    if (wasDupe) {
      await addBriks(earned);
    } else {
      await svc.updateState(state.copyWith(unlockedIds: newUnlocked));
    }

    return ClaimResult(
      roll: LootRoll(
        cosmeticId: roll,
        tier:       BrickTier.common,
        rolledAt:   DateTime.now(),
      ),
      briksEarned: earned,
      wasDupe:     wasDupe,
    );
  }

  // ── Bundle checking ──────────────────────────────────────────────────────
  Future<List<CosmeticBundle>> checkBundles(CollectionProvider col) async {
    final newBundles = <CosmeticBundle>[];

    for (final bundle in AllBundles.all) {
      if (_unlockedBundles.contains(bundle.id)) continue;
      if (_meetsBundleCondition(bundle.id, col)) {
        newBundles.add(bundle);
        _unlockedBundles.add(bundle.id);
      }
    }

    if (newBundles.isNotEmpty) await _saveBundles();
    return newBundles;
  }

  bool _meetsBundleCondition(String bundleId, CollectionProvider col) {
    final sets   = col.sets;
    final market = col.totalMarket;
    final paid   = col.totalPaid;
    final roi    = paid > 0 ? (market - paid) / paid * 100 : 0.0;

    switch (bundleId) {
      case 'bundle_xwing':
        return sets.where((s) =>
            s.theme?.toLowerCase().contains('star wars') ?? false).length >= 5;
      case 'bundle_ucs':
        return sets.where((s) =>
            (s.subtheme?.toLowerCase().contains('ultimate collector') ?? false) ||
            (s.theme?.toLowerCase().contains('ultimate collector') ?? false)).length >= 3;
      case 'bundle_castle':
        return sets.any((s) => s.theme?.toLowerCase().contains('castle') ?? false);
      case 'bundle_viking':
        return sets.length >= 25;
      case 'bundle_city':
        return sets.length >= 10;
      case 'bundle_master':
        return sets.length >= 50;
      case 'bundle_space':
        return market >= 5000;
      case 'bundle_gold':
        return market >= 10000;
      case 'bundle_pearl':
        return roi >= 100;

      // ── Phase-2 theme bundles ──────────────────────────────────────────
      case 'bundle_spellbound':
        return _themeCount(sets, ['harry potter', 'wizarding']) >= 5;
      case 'bundle_botanical':
        return _themeCount(sets, ['botanical']) >= 3;
      case 'bundle_grandprix':
        return _themeCount(sets, ['speed champions']) >= 5;
      case 'bundle_storm':
        return _themeCount(sets, ['ninjago']) >= 8;
      case 'bundle_landmark':
        return _themeCount(sets, ['icons', 'architecture']) >= 3;
      case 'bundle_frostfall':
        return _themeCount(sets, ['winter village', 'winter']) >= 2;
      case 'bundle_curio':
        return _themeCount(sets, ['ideas']) >= 3;

      default:
        return false;
    }
  }

  /// Counts sets whose theme OR subtheme contains any of [needles]
  /// (all lower-case substrings).
  int _themeCount(List sets, List<String> needles) {
    return sets.where((s) {
      final t  = (s.theme as String?)?.toLowerCase() ?? '';
      final st = (s.subtheme as String?)?.toLowerCase() ?? '';
      return needles.any((n) => t.contains(n) || st.contains(n));
    }).length;
  }

  // ── Equip a full bundle ──────────────────────────────────────────────────
  Future<void> equipBundle(String bundleId) async {
    final bundle = AllBundles.byId[bundleId];
    if (bundle == null) return;

    final svc   = AchievementService.instance;
    var   state = svc.state;

    // Unlock all pieces — a piece already owned (reused across bundles/
    // theme tiers) pays out Briks instead of granting nothing, same as any
    // other dupe.
    final newUnlocked = Set<String>.from(state.unlockedIds);
    var earned = 0;
    for (final id in bundle.cosmeticIds) {
      earned += unlockOrDupePayout(id, newUnlocked);
    }
    state = state.copyWith(unlockedIds: newUnlocked);

    // Equip each piece -- background resolves against the background catalog,
    // every figure slot (head/hat/torso/legs/item) against the pixel
    // catalog now that bundle.cosmeticIds points at it.
    for (final id in bundle.cosmeticIds) {
      final sc = bg.backgroundCosmeticsById[id];
      if (sc != null) {
        if (sc.slot == bg.CosmeticSlot.background) {
          state = state.copyWith(backgroundId: id);
        }
        continue;
      }
      final pc = pixel.pixelCosmeticsById[id];
      if (pc == null) continue;
      state = switch (pc.slot) {
        pixel.PixelSlot.head  => state.copyWith(headId: id),
        pixel.PixelSlot.hat   => state.copyWith(hatId: id),
        pixel.PixelSlot.torso => state.copyWith(torsoId: id),
        pixel.PixelSlot.legs  => state.copyWith(legsId: id),
        pixel.PixelSlot.item  => state.copyWith(itemId: id),
      };
    }

    await svc.updateState(state);
    if (earned > 0) await addBriks(earned);
  }

  // ── Unlock bundle pieces only (no equip) ─────────────────────────────────
  Future<void> unlockBundle(String bundleId) async {
    final bundle = AllBundles.byId[bundleId];
    if (bundle == null) return;

    final svc   = AchievementService.instance;
    final state = svc.state;
    final newUnlocked = Set<String>.from(state.unlockedIds);
    var earned = 0;
    for (final id in bundle.cosmeticIds) {
      earned += unlockOrDupePayout(id, newUnlocked);
    }
    await svc.updateState(state.copyWith(unlockedIds: newUnlocked));
    if (earned > 0) await addBriks(earned);
  }

  // ── DEV ONLY — remove before release ─────────────────────────────────────
  Future<void> debugUnlockAll() async {
    final svc    = AchievementService.instance;
    final allIds = _rewardPool.map((c) => c.id).toSet();
    await svc.updateState(svc.state.copyWith(unlockedIds: allIds));
  }
}
