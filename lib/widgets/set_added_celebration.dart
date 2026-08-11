// lib/widgets/set_added_celebration.dart
//
// Brief, non-blocking celebration shown after successfully adding a set --
// applies the same "rarer = more elaborate" reveal language the loot
// system already uses (see loot_roll_widget.dart), just driven by the
// set's price instead of a cosmetic's catalog rarity, and reusing the same
// 5-tier common/uncommon/rare/epic/legendary color scale (SpriteRarityX)
// for visual consistency with the rest of the app's reward language rather
// than inventing a second palette.
//
// Value bands below are a first guess, not derived from any real
// distribution of set prices in this app -- tune them against feedback the
// same way pixel_avatar_widget.dart's proportions were.
//
// Deliberately non-blocking and auto-dismissing (unlike LootRollWidget's
// tap-required reveal): this fires on every single set add, including
// cheap ones, so requiring a tap every time would make adding sets feel
// like a chore instead of a flourish.
import 'package:flutter/material.dart';
import '../modules/avatar/data/sprite_cosmetics.dart' show SpriteRarity, SpriteRarityX;
import '../theme/app_theme.dart';
import 'brick_burst.dart';

class _ValueTier {
  final SpriteRarity rarity;
  final String label;
  const _ValueTier(this.rarity, this.label);
}

_ValueTier _tierFor(double? value) {
  final v = value ?? 0;
  if (v >= 350) return const _ValueTier(SpriteRarity.legendary, 'LEGENDARY ADD!');
  if (v >= 150) return const _ValueTier(SpriteRarity.epic, 'Awesome!');
  if (v >= 60)  return const _ValueTier(SpriteRarity.rare, 'Great add!');
  if (v >= 25)  return const _ValueTier(SpriteRarity.uncommon, 'Nice add!');
  return const _ValueTier(SpriteRarity.common, 'Added!');
}

/// Inserts a brief, self-removing overlay celebrating a just-added set,
/// scaled by [value] -- pass retail (or paid, if retail is unknown) since
/// there's no eBay price yet for a set that was just added this instant.
void showSetAddedCelebration(BuildContext context, {double? value}) {
  final tier = _tierFor(value);
  final overlayState = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SetAddedOverlay(
      tier: tier,
      onDone: () => entry.remove(),
    ),
  );
  overlayState.insert(entry);
}

class _SetAddedOverlay extends StatelessWidget {
  final _ValueTier tier;
  final VoidCallback onDone;
  const _SetAddedOverlay({required this.tier, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final intensity = tier.rarity.index / 4.0;
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
            BrickBurstOverlay(
              color: tier.rarity.color,
              intensity: intensity,
              // Bigger adds linger a touch longer, same "more elaborate for
              // rarer" scaling the burst intensity already gets.
              duration: Duration(milliseconds: (600 + intensity * 500).round()),
              onComplete: onDone,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: BT.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: tier.rarity.color, width: 2),
                boxShadow: [BoxShadow(
                    color: tier.rarity.color.withOpacity(.4), blurRadius: 12)],
              ),
              child: Text(tier.label,
                  style: BT.display(size: 15, color: tier.rarity.color)),
            ),
          ]),
        ),
      ),
    );
  }
}
