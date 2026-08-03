// lib/modules/avatar/widgets/avatar_widget.dart
//
// Thin adapter over PixelAvatarWidget so screens built against this
// state/size/animated/showBackground API don't need to change call sites.
// Character layers (head/hat/torso/legs) render from the new pixel-art
// catalog (data/pixel_cosmetics.dart) now; background is still the flat
// procedural color panel exactly as before -- none of the pixel-art batch
// is background art, so Den backgrounds weren't touched by this cutover.
//
// `animated` now actually gates PixelAvatarWidget's per-layer frame ticker
// (it didn't used to -- the catalog had no animated entries yet). Default
// stays false here (unlike PixelAvatarWidget's own default of true) so
// existing call sites that never explicitly asked for animation don't
// suddenly start animating the first time an animated cosmetic gets
// equipped -- only screens that already pass animated: true (dashboard
// card, Den scene, loot reveal) do.
//
// `showGroundAccessory` DOES gate itemId now (it briefly didn't -- see git
// history -- which was a real bug: the Den renders its equipped item as its
// own independent floor object via ground_accessory.dart, positioned
// against the shelf art rather than next to the figure, and passes
// showGroundAccessory: false specifically to suppress the inline item band
// here so it doesn't ALSO show attached to the avatar's own box). Every
// other call site (dashboard card, popups, avatar_editor.dart's preview)
// leaves this at the default true and wants the item inline.
import 'package:flutter/material.dart';
import '../models/avatar_state.dart';
import '../data/backgrounds_art.dart' as bgArt;
import 'pixel_avatar_widget.dart';

class AvatarWidget extends StatelessWidget {
  final AvatarState state;
  final double size;
  final bool animated;
  final bool showBackground;
  final bool showGroundAccessory;

  const AvatarWidget({
    super.key,
    required this.state,
    this.size = 120,
    this.animated = false,
    this.showBackground = true,
    this.showGroundAccessory = true,
  });

  @override
  Widget build(BuildContext context) {
    // Was Center. The figure itself only occupies the left portion of its
    // own (item-band-inclusive) width, so dead-centering it in the badge
    // left the item band cramped against the badge's right edge with
    // little margin. Align biases the whole thing left instead, opening up
    // consistent breathing room on the right for the equipped item to
    // actually read as "standing next to" the figure rather than crowded
    // into the corner. -0.35 is a first guess, not measured against a
    // render yet.
    final figure = Align(
      alignment: const Alignment(-0.35, 0),
      child: PixelAvatarWidget(
        // The body canvas isn't square, so it's centered inside the size x
        // size badge below rather than stretched to fill it. Started at
        // 0.62 (read too small/lost in the badge), bumped to 0.7, then
        // bumped again +5% to 0.735 on explicit request to enlarge the
        // whole figure -- still comfortably inside the badge (~84% of its
        // height, ~62% of its width even with an item equipped) so nothing
        // clips against the rounded corners.
        size: size * 0.735,
        animated: animated,
        state: PixelAvatarState(
          headId: state.headId,
          hatId: state.hatId,
          torsoId: state.torsoId,
          legsId: state.legsId,
          itemId: showGroundAccessory ? state.itemId : null,
        ),
      ),
    );

    if (!showBackground) return figure;

    final palette = bgArt.bgPalettes[state.backgroundId] ?? bgArt.bgPalettes['bg_cream']!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.avatarBg,
        borderRadius: BorderRadius.circular(size * .1),
      ),
      clipBehavior: Clip.antiAlias,
      child: figure,
    );
  }
}
