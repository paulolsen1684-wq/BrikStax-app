// lib/modules/avatar/widgets/bundle_popup.dart
//
// NOTE: Card chrome stays fixed light (BT.white / BT.ink) — always shown over
// a dark barrier, same rationale as achievement_popup and loot_roll_widget.
// The "Save for later" button and pieces list use bt.* so they're readable
// against the fixed-white card in both light and dark mode.
import 'package:flutter/material.dart';
import '../data/pixel_cosmetics.dart' as pixel;
import '../data/sprite_cosmetics.dart' as sprite;
import '../models/bundle.dart';
import '../models/avatar_state.dart';
import '../services/loot_service.dart';
import 'avatar_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class BundlePopup extends StatefulWidget {
  final CosmeticBundle bundle;
  final VoidCallback   onDismiss;

  const BundlePopup({
    super.key,
    required this.bundle,
    required this.onDismiss,
  });

  static Future<void> show(
      BuildContext context, CosmeticBundle bundle) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BundlePopup(
        bundle:    bundle,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<BundlePopup> createState() => _BundlePopupState();
}

class _BundlePopupState extends State<BundlePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // Background resolves against the sprite catalog; every figure slot
  // (head/hat/torso/legs/item) against the pixel catalog now that
  // bundles.dart's cosmeticIds point at it. Base state is a blank
  // AvatarState (no head/torso/legs) rather than the player's real
  // equipped state, same as before -- this is meant to preview ONLY the
  // bundle's own pieces, not blend with whatever's currently worn.
  AvatarState _bundlePreview() {
    var state = const AvatarState();
    for (final id in widget.bundle.cosmeticIds) {
      final sc = sprite.spriteCosmeticsById[id];
      if (sc != null) {
        if (sc.slot == sprite.CosmeticSlot.background) {
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
    return state;
  }

  @override
  Widget build(BuildContext context) {
    final bt     = context.bt;
    final bundle = widget.bundle;
    final color  = bundle.rarityColor;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Fixed white — must pop against dark barrier
            color: BT.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(color: color, offset: const Offset(4, 4))
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: BT.ink,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('BUNDLE UNLOCKED',
                  style: BT.display(size: 12, color: color)),
            ),
            const SizedBox(height: 16),
            Text(bundle.emoji,
                style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(bundle.name,
                style: BT.display(size: 24),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(bundle.description,
                style: BT.mono(size: 11, color: BT.tx2),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // Preview avatar with full bundle equipped
            AvatarWidget(state: _bundlePreview(), size: 110),
            const SizedBox(height: 14),

            // Pieces list — uses bt tokens so it reads inside white card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bt.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Includes:',
                      style: BT.mono(size: 9, color: bt.tx3)),
                  const SizedBox(height: 6),
                  ...bundle.cosmeticIds.map((id) {
                    final sc = sprite.spriteCosmeticsById[id];
                    final pc = pixel.pixelCosmeticsById[id];
                    final name  = sc?.name  ?? pc?.name;
                    final color = sc?.rarity.color ?? pc?.rarity.color;
                    final label = sc?.rarity.label ?? pc?.rarity.label;
                    if (name == null) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(name, style: BT.body(size: 12)),
                        const Spacer(),
                        Text(label ?? '',
                            style: BT.mono(size: 8,
                                color: color ?? BT.tx3)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await LootService.instance.unlockBundle(bundle.id);
                    widget.onDismiss();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      // Secondary button — bt tokens so it reads
                      // clearly against the white card in dark mode
                      color: bt.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: bt.cardBorder, width: BT.bw),
                    ),
                    child: Text('Save for later',
                        textAlign: TextAlign.center,
                        style: BT.body(size: 13, color: bt.tx)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await LootService.instance.equipBundle(bundle.id);
                    widget.onDismiss();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BT.ink, width: BT.bw),
                      boxShadow: BT.shadowSm,
                    ),
                    child: Text('Equip all!',
                        textAlign: TextAlign.center,
                        style: BT.body(size: 13)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
