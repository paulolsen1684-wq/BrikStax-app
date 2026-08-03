// lib/modules/avatar/services/secret_item_service.dart
//
// Secret cosmetics (SpriteCosmetic.isSecret: true in sprite_cosmetics.dart)
// are reachable two ways, same as the user asked for:
//   1. A hidden magic code, entered through Add Set exactly like DevMode's
//      magic set number -- CollectionProvider.addSet checks this service
//      right after DevMode's check, before the number ever touches the
//      real collection. Unlike DevMode (which flips a global toggle), a
//      matched code here grants exactly one specific cosmetic id.
//   2. A rare bonus drop from LootService's daily claim / bonus rolls --
//      see LootService._maybeSecretDrop. That path pulls from every
//      isSecret cosmetic in the sprite catalog automatically; it does NOT
//      need a code registered here to be eligible.
//
// To add a new secret item once its art exists:
//   1. Add its SpriteCosmetic entry in sprite_cosmetics.dart with
//      isSecret: true and a frames: [...] list (3 or 4 asset paths).
//   2. Optionally add a {code: id} pair to SecretItemCodes.byCode below,
//      if it should also be reachable by code (not required -- an
//      isSecret item with no code is still eligible for the rare loot
//      drop, just code-unlockable ones need an entry here).
// Nothing else needs to change; the loot pool and catalog-grid hiding
// (avatar_editor.dart's _SpriteTile) both key off isSecret generically.
import '../data/sprite_cosmetics.dart';
import 'achievement_service.dart';

class SecretItemCodes {
  SecretItemCodes._();

  // Magic set numbers -> the cosmetic id they grant. Pick codes the same
  // way DevMode's was picked: not a real/plausible LEGO set number, so it
  // can never collide with something a tester or player actually types.
  static const Map<String, String> byCode = {
    // Nov 5, 1955 -- the lightning-strike date. Not a plausible real LEGO
    // set number (6 digits, no set numbering scheme looks like a date).
    '110555': 'accessory_57', // Flux Capacitor Case
  };
}

class SecretItemService {
  SecretItemService._();
  static final instance = SecretItemService._();

  // Same normalization as DevMode._norm -- strips leading zeros so "007",
  // "07", and "7" all match the same code.
  String _norm(String s) {
    final t = s.trim();
    final stripped = t.replaceFirst(RegExp(r'^0+'), '');
    return stripped.isEmpty ? '0' : stripped;
  }

  /// Checks [setNum] against every registered secret code. On a match,
  /// grants the cosmetic (idempotent if already unlocked) and returns its
  /// display name for a confirmation toast. Returns null on no match.
  Future<String?> handleCode(String setNum) async {
    final target = _norm(setNum);
    for (final entry in SecretItemCodes.byCode.entries) {
      if (_norm(entry.key) != target) continue;
      final cosmetic = spriteCosmeticsById[entry.value];
      if (cosmetic == null) return null; // code registered but id typo'd/missing
      await _grant(cosmetic.id);
      return cosmetic.name;
    }
    return null;
  }

  Future<void> _grant(String cosmeticId) async {
    final svc = AchievementService.instance;
    if (svc.state.unlockedIds.contains(cosmeticId)) return;
    final unlocked = Set<String>.from(svc.state.unlockedIds)..add(cosmeticId);
    await svc.updateState(svc.state.copyWith(unlockedIds: unlocked));
  }
}
