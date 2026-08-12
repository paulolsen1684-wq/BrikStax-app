// lib/modules/avatar/widgets/achievement_popup.dart
//
// NOTE: This popup is always rendered over a dark barrier (Colors.black87).
// The card intentionally uses fixed light colors (BT.white / BT.yellow / BT.ink)
// so it reads clearly against the overlay regardless of the app theme.
// Only secondary text colors are migrated to bt.* tokens.
//
// Achievement rewards resolve against the pixel catalog (figure slots) or
// the background catalog (background_cosmetics.dart) now --
// achievements.dart's cosmeticId values were remapped off the retired
// figure catalog once the pixel catalog had real rarity data to support
// this.
import 'package:flutter/material.dart';
import '../data/achievements.dart';
import '../data/pixel_cosmetics.dart' as pixel;
import '../data/background_cosmetics.dart' as bg;
import '../models/avatar_state.dart';
import '../services/achievement_service.dart';
import 'avatar_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class AchievementPopup extends StatefulWidget {
  final String       achievementId;
  final AvatarState  currentState;
  final VoidCallback onDismiss;

  const AchievementPopup({
    super.key,
    required this.achievementId,
    required this.currentState,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context,
    String achievementId,
    AvatarState state,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AchievementPopup(
        achievementId: achievementId,
        currentState:  state,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    // bt used only for secondary text colors — card chrome stays fixed light
    final bt = context.bt;

    final achievement = AllAchievements.byId[widget.achievementId];
    if (achievement == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onDismiss());
      return const SizedBox();
    }

    final bgCosmetic = bg.backgroundCosmeticsById[achievement.cosmeticId];
    final pixelCosmetic  = pixel.pixelCosmeticsById[achievement.cosmeticId];
    final hasReward = bgCosmetic != null || pixelCosmetic != null;

    final rewardName  = bgCosmetic?.name  ?? pixelCosmetic?.name;
    final rewardColor = bgCosmetic?.rarity.color ?? pixelCosmetic?.rarity.color;
    final rewardLabel = bgCosmetic?.rarity.label ?? pixelCosmetic?.rarity.label;
    final rewardEmoji = bgCosmetic != null
        ? _bgSlotEmoji(bgCosmetic.slot)
        : pixelCosmetic != null
            ? _pixelSlotEmoji(pixelCosmetic.slot)
            : '🖼️';

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // Fixed white — must read against dark barrier
              color: BT.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BT.yellow, width: 3),
              boxShadow: const [
                BoxShadow(color: BT.yellow, offset: Offset(4, 4)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: BT.ink,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('ACHIEVEMENT UNLOCKED',
                    style: BT.display(size: 12, color: BT.yellow)),
              ),
              const SizedBox(height: 20),
              Text(achievement.emoji,
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(achievement.name,
                  style: BT.display(size: 26),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(achievement.description,
                  style: BT.mono(size: 11, color: BT.tx2),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              // Divider stays cream — it's inside the fixed-white card
              const Divider(color: BT.cream2),
              const SizedBox(height: 16),
              if (hasReward) ...[
                Text('New cosmetic unlocked!',
                    style: BT.mono(size: 9, color: BT.tx3)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rewardColor!.withOpacity(.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: rewardColor, width: 1.5),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min, children: [
                    Text(rewardEmoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(rewardName!,
                          style: BT.body(size: 13)),
                      Text(rewardLabel!,
                          style: BT.mono(size: 9,
                              color: rewardColor)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                AvatarWidget(
                  state: _previewState(bgCosmetic, pixelCosmetic),
                  size: 110,
                ),
                const SizedBox(height: 16),
              ],
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        // Secondary button — uses surface so it reads
                        // against the fixed-white card in both modes
                        color: bt.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: bt.cardBorder, width: BT.bw),
                      ),
                      child: Text('Later',
                          textAlign: TextAlign.center,
                          style: BT.body(size: 14, color: bt.tx)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (bgCosmetic != null) {
                        AchievementService.instance.equipBackground(bgCosmetic);
                      } else if (pixelCosmetic != null) {
                        AchievementService.instance.equipPixel(pixelCosmetic);
                      }
                      widget.onDismiss();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: BT.yellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: BT.ink, width: BT.bw),
                        boxShadow: BT.shadowSm,
                      ),
                      child: Text('Equip!',
                          textAlign: TextAlign.center,
                          style: BT.body(size: 14)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  // Background resolves against the background catalog; every figure slot
  // (head/hat/torso/legs/item) against the pixel catalog now that
  // achievements.dart's cosmeticId values point at it.
  AvatarState _previewState(bg.BackgroundCosmetic? bgCosmetic, pixel.PixelCosmetic? pixelCosmetic) {
    final base = AchievementService.instance.state;
    if (bgCosmetic != null && bgCosmetic.slot == bg.CosmeticSlot.background) {
      return base.copyWith(backgroundId: bgCosmetic.id);
    }
    if (pixelCosmetic != null) {
      return switch (pixelCosmetic.slot) {
        pixel.PixelSlot.head  => base.copyWith(headId: pixelCosmetic.id),
        pixel.PixelSlot.hat   => base.copyWith(hatId: pixelCosmetic.id),
        pixel.PixelSlot.torso => base.copyWith(torsoId: pixelCosmetic.id),
        pixel.PixelSlot.legs  => base.copyWith(legsId: pixelCosmetic.id),
        pixel.PixelSlot.item  => base.copyWith(itemId: pixelCosmetic.id),
      };
    }
    return base;
  }

  // CosmeticSlot only has one value now (background) -- the figure-slot
  // cases this used to switch over (head/helmet/outfit/accessory) were
  // removed 2026-08-12 along with the rest of the retired figure catalog's
  // leftovers in background_cosmetics.dart. See _pixelSlotEmoji below for the
  // figure-slot equivalent, which is what achievements.dart's cosmeticId
  // values actually resolve against now.
  String _bgSlotEmoji(bg.CosmeticSlot slot) => '🖼️';

  String _pixelSlotEmoji(pixel.PixelSlot slot) => switch (slot) {
    pixel.PixelSlot.head  => '🟡',
    pixel.PixelSlot.hat   => '🎩',
    pixel.PixelSlot.torso => '👕',
    pixel.PixelSlot.legs  => '👖',
    pixel.PixelSlot.item  => '✋',
  };
}
