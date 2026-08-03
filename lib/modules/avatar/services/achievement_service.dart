// lib/modules/avatar/services/achievement_service.dart
//
// Two equip paths now: equipPixel() for the live figure catalog (head/hat/
// torso/legs/item, data/pixel_cosmetics.dart) and equipSprite() for
// background only -- sprite_cosmetics.dart's head/helmet/outfit/accessory
// entries were retired along with the catalog data itself, but the
// CosmeticSlot enum there still declares those cases (Dart requires an
// exhaustive switch), so equipSprite keeps them as harmless no-ops rather
// than deleting the enum values and chasing every switch that touches them.
//
// Achievement/bundle/hidden-theme rewards still reference old sprite ids
// (e.g. 'accessory_02') that resolve to nothing in either catalog now --
// known, not yet remapped to the new 20-item pixel catalog. Nothing here
// crashes on an unresolvable id (every UI that reads a reward already
// null-checks), it just silently grants no visible cosmetic until that
// remap happens.

import 'package:flutter/material.dart';
import '../../../providers/collection.dart';
import '../data/achievements.dart';
import '../data/pixel_cosmetics.dart';
import '../data/sprite_cosmetics.dart' as sprite;
import '../models/avatar_state.dart';
import 'avatar_storage.dart';

class AchievementService extends ChangeNotifier {
  AchievementService._();
  static final instance = AchievementService._();

  AvatarState _state = AvatarState.defaults;
  AvatarState get state => _state;

  final List<String> _pendingUnlocks = [];
  List<String> get pendingUnlocks => List.unmodifiable(_pendingUnlocks);

  Future<void> init() async {
    _state = await AvatarStorage.instance.load();
    // A SAVED state only has whatever ids existed in AvatarState.starterIds
    // at the time it was written -- if that starter set ever grows (a new
    // required-slot default, say), an existing save wouldn't have the new
    // id and could end up with a required slot pointing at nothing
    // unlocked. Re-union against the CURRENT starter set on every load so
    // that can't happen. Deliberately NOT unioning against the full pixel
    // catalog anymore -- that was a placeholder for when there was no real
    // unlock/loot economy yet (see loot_service.dart's reward pool now);
    // doing it here would silently re-unlock everything on every launch and
    // defeat the whole reward system.
    final withStarters = {
      ..._state.unlockedIds,
      ...AvatarState.starterIds,
    };
    if (withStarters.length != _state.unlockedIds.length) {
      _state = _state.copyWith(unlockedIds: withStarters);
      await AvatarStorage.instance.save(_state);
    }
    notifyListeners();
  }

  Future<void> updateState(AvatarState newState) async {
    _state = newState;
    await AvatarStorage.instance.save(_state);
    notifyListeners();
  }

  Future<List<String>> check(CollectionProvider col) async {
    final newlyEarned = <String>[];

    for (final achievement in AllAchievements.all) {
      if (_state.earnedIds.contains(achievement.id)) continue;
      if (_meetsCondition(achievement.id, col)) newlyEarned.add(achievement.id);
    }
    if (newlyEarned.isEmpty) return [];

    final newUnlocked = Set<String>.from(_state.unlockedIds);
    final newEarned   = Set<String>.from(_state.earnedIds);

    for (final id in newlyEarned) {
      final achievement = AllAchievements.byId[id]!;
      newUnlocked.add(achievement.cosmeticId);
      newEarned.add(id);
    }

    final allOtherIds = AllAchievements.all
        .where((a) => a.id != 'legendary_all')
        .map((a) => a.id)
        .toSet();
    if (allOtherIds.every((id) => newEarned.contains(id)) &&
        !newEarned.contains('legendary_all')) {
      final la = AllAchievements.byId['legendary_all']!;
      newUnlocked.add(la.cosmeticId);
      newEarned.add('legendary_all');
      newlyEarned.add('legendary_all');
    }

    // "gold set" = px_torso_icetroopersuit + px_legs_icetrooper (from
    // roi_100 / legendary_roi) -- was head_18 + outfit_18 against the old
    // retired sprite catalog, remapped onto the pixel catalog's Ice Base
    // Trooper set. legendary_gold's own reward (px_hat_icetrooper) is a
    // separate bonus piece, not part of the set itself, so it can be part
    // of its own trigger condition without the old circularity bug (a
    // gold-set piece requiring itself to unlock).
    if (newUnlocked.containsAll(['px_torso_icetroopersuit', 'px_legs_icetrooper']) &&
        !newEarned.contains('legendary_gold')) {
      final lg = AllAchievements.byId['legendary_gold']!;
      newUnlocked.add(lg.cosmeticId);
      newEarned.add('legendary_gold');
      newlyEarned.add('legendary_gold');
    }

    _state = _state.copyWith(unlockedIds: newUnlocked, earnedIds: newEarned);
    _pendingUnlocks.addAll(newlyEarned);

    await AvatarStorage.instance.save(_state);
    notifyListeners();
    return newlyEarned;
  }

  bool _meetsCondition(String id, CollectionProvider col) {
    final sets   = col.sets;
    final market = col.totalMarket;
    final paid   = col.totalPaid;
    final roi    = paid > 0 ? (market - paid) / paid * 100 : 0.0;

    switch (id) {
      case 'first_set':      return sets.isNotEmpty;
      case 'first_ebay':     return sets.any((s) => s.ebayAvg != null);
      case 'sets_10':        return sets.length >= 10;
      case 'sets_25':        return sets.length >= 25;
      case 'sets_50':        return sets.length >= 50;
      case 'sets_100':       return sets.length >= 100;
      case 'legendary_sets': return sets.length >= 250;

      case 'sealed_5':  return sets.where((s) => s.status == 'sealed').length >= 5;
      case 'sealed_10': return sets.where((s) => s.status == 'sealed').length >= 10;
      case 'sealed_25': return sets.where((s) => s.status == 'sealed').length >= 25;

      case 'value_1k':          return market >= 1000;
      case 'value_5k':          return market >= 5000;
      case 'value_10k':         return market >= 10000;
      case 'value_25k':         return market >= 25000;
      case 'legendary_portfolio': return market >= 50000;

      case 'roi_50':  return sets.any((s) => (s.roi ?? 0) >= 50);
      case 'roi_100': return sets.any((s) => (s.roi ?? 0) >= 100);
      case 'roi_200': return sets.any((s) => (s.roi ?? 0) >= 200);
      case 'roi_500': return sets.any((s) => (s.roi ?? 0) >= 500);
      case 'legendary_roi': return roi >= 100;

      case 'theme_starwars':
        return sets.where((s) =>
            s.theme?.toLowerCase().contains('star wars') ?? false).length >= 5;
      case 'theme_ucs':
        return sets.where((s) =>
            (s.subtheme?.toLowerCase().contains('ultimate collector') ?? false) ||
            (s.theme?.toLowerCase().contains('ultimate collector') ?? false)).length >= 3;
      case 'theme_icons':
        return sets.where((s) =>
            s.theme?.toLowerCase().contains('icons') ?? false).length >= 5;
      case 'theme_technic':
        return sets.where((s) =>
            s.theme?.toLowerCase().contains('technic') ?? false).length >= 5;

      default: return false;
    }
  }

  void dismissUnlock(String achievementId) {
    _pendingUnlocks.remove(achievementId);
    notifyListeners();
  }

  // Background only now -- head/helmet/outfit/accessory are retired
  // no-ops, kept solely so this switch stays exhaustive over
  // sprite.CosmeticSlot without deleting the enum itself.
  Future<void> equipSprite(sprite.SpriteCosmetic cosmetic) async {
    if (!_state.unlockedIds.contains(cosmetic.id)) return;
    if (cosmetic.slot != sprite.CosmeticSlot.background) return;

    _state = _state.copyWith(backgroundId: cosmetic.id);
    await AvatarStorage.instance.save(_state);
    notifyListeners();
  }

  // Equip a cosmetic from the pixel-art figure catalog (head/hat/torso/
  // legs/item) -- the live equip path for everything except background.
  Future<void> equipPixel(PixelCosmetic cosmetic) async {
    if (!_state.unlockedIds.contains(cosmetic.id)) return;

    _state = switch (cosmetic.slot) {
      PixelSlot.head  => _state.copyWith(headId: cosmetic.id),
      PixelSlot.hat   => _state.copyWith(hatId: cosmetic.id),
      PixelSlot.torso => _state.copyWith(torsoId: cosmetic.id),
      PixelSlot.legs  => _state.copyWith(legsId: cosmetic.id),
      PixelSlot.item  => _state.copyWith(itemId: cosmetic.id),
    };
    await AvatarStorage.instance.save(_state);
    notifyListeners();
  }

  Future<void> unequipPixel(PixelSlot slot) async {
    _state = switch (slot) {
      PixelSlot.hat  => _state.copyWith(clearHat: true),
      PixelSlot.item => _state.copyWith(clearItem: true),
      _ => _state,
    };
    await AvatarStorage.instance.save(_state);
    notifyListeners();
  }
}
