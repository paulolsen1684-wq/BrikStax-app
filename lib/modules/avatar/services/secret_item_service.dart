// lib/modules/avatar/services/secret_item_service.dart
//
// Secret cosmetics (isSecret: true, either PixelCosmetic in
// pixel_cosmetics.dart -- e.g. px_item_secretxwing -- or SpriteCosmetic in
// sprite_cosmetics.dart, though no background currently sets it) are
// reachable two ways:
//   1. A hidden magic code, entered through Add Set exactly like DevMode's
//      magic set number -- CollectionProvider.addSet checks this service
//      right after DevMode's check, before the number ever touches the
//      real collection. Unlike DevMode (which flips a global toggle), a
//      matched code here grants exactly one specific cosmetic id.
//   2. A rare bonus drop from LootService's daily claim / bonus rolls --
//      see LootService._maybeSecretDrop, which already checks isSecret
//      items across both catalogs. That path does NOT need a code
//      registered here to be eligible.
//
// 2026-08-12: SecretItemCodes.byCode's only entry ('110555' ->
// 'accessory_57', a Flux Capacitor Case from the retired figure catalog)
// pointed at an id that hasn't existed since that catalog was deleted --
// handleCode() was silently returning null for it, so the code granted
// nothing. Removed rather than repointed at a real id, since no secret
// item has been designated as code-unlockable yet; add a fresh {code: id}
// entry here once one is. Also fixed handleCode()/_grant() to check the
// pixel catalog as well as sprite -- they only ever checked
// spriteCosmeticsById, so a code pointed at a pixel id (where secret items
// actually live now, e.g. px_item_secretxwing) would have hit this exact
// same silent-failure mode again.
//
// To add a new secret item once its art exists:
//   1. Add its PixelCosmetic (or SpriteCosmetic, for a background) entry
//      with isSecret: true and a frames: [...] list if it should animate.
//   2. Optionally add a {code: id} pair to SecretItemCodes.byCode below,
//      if it should also be reachable by code (not required -- an
//      isSecret item with no code is still eligible for the rare loot
//      drop, just code-unlockable ones need an entry here).
// Nothing else needs to change; the loot pool and catalog-grid hiding key
// off isSecret generically, on both catalogs.
import '../data/pixel_cosmetics.dart';
import '../data/sprite_cosmetics.dart';
import 'achievement_service.dart';

class SecretItemCodes {
  SecretItemCodes._();

  // Magic set numbers -> the cosmetic id they grant (sprite or pixel
  // catalog id, either works -- see handleCode below). Pick codes the same
  // way DevMode's was picked: not a real/plausible LEGO set number, so it
  // can never collide with something a tester or player actually types.
  static const Map<String, String> byCode = {};
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
      // Checks both catalogs -- a code-registered id could point at either
      // one, same as every other cross-catalog lookup in this system
      // (LootService.rarityOf does the same sprite-then-pixel fallback).
      final id = entry.value;
      final name = spriteCosmeticsById[id]?.name ?? pixelCosmeticsById[id]?.name;
      if (name == null) return null; // code registered but id typo'd/missing
      await _grant(id);
      return name;
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
