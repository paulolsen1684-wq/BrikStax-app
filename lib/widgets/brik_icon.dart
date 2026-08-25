// lib/widgets/brik_icon.dart
//
// Shared "Brik" currency icon -- real animated art (assets/blocks/block1
// -4.png, a 4-frame gold-block shine sweep), replacing every plain "🧱"
// emoji glyph used as an icon in the UI, 2026-08-25. Emoji ignore Flutter's
// color:/tint and render in their own fixed style regardless of theme --
// same reason this app avoids them for icons elsewhere (see dashboard
// .dart's _TodayMiniCard doc comment). This also replaces two duplicate
// hand-rolled CustomPainters that drew the same "brick" concept
// independently (_MiniBrickPainter in daily_claim_screen.dart,
// _BrickPainter/_PixelBrick in loot_roll_widget.dart) with one real, shared
// asset instead of two copies of bespoke drawing code.
//
// Those two painters were tinted per-instance (BrickTier color on the
// Daily Claim screen; a cycling flash color during the loot-roll spin) --
// the new art is fixed gold with baked-in shading, so that tinting is
// gone by design (confirmed with the user rather than assumed): one
// consistent Brik icon everywhere now, not a recolorable one.
//
// NOT used for share-sheet caption text or push/local notification bodies
// -- those are plain OS-level text with no way to embed an image, so they
// keep the literal "🧱" glyph (see set_share_screen.dart/
// collection_share_screen.dart/den_share_screen.dart's SharePlus `text:`
// params and local_notification_service.dart's notification body).
import 'package:flutter/material.dart';

const List<String> brikIconFrames = [
  'assets/blocks/block1.png',
  'assets/blocks/block2.png',
  'assets/blocks/block3.png',
  'assets/blocks/block4.png',
];

/// Drop-in replacement for `Text('🧱', style: TextStyle(fontSize: N))` --
/// [size] plays the same role as that old fontSize. Animates by default
/// (900ms full loop across the 4 frames, matching the shine-sweep cadence
/// PixelCosmetic's own animated items already use); pass
/// `animated: false` for tight inline contexts (e.g. spliced into a
/// sentence via WidgetSpan) where a static icon reads cleaner.
class BrikIcon extends StatefulWidget {
  final double size;
  final bool animated;
  const BrikIcon({super.key, this.size = 16, this.animated = true});

  @override
  State<BrikIcon> createState() => _BrikIconState();
}

class _BrikIconState extends State<BrikIcon> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl == null) {
      return Image.asset(brikIconFrames.first,
          width: widget.size, height: widget.size, filterQuality: FilterQuality.medium);
    }
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final frame = (ctrl.value * brikIconFrames.length)
            .floor()
            .clamp(0, brikIconFrames.length - 1);
        return Image.asset(brikIconFrames[frame],
            width: widget.size, height: widget.size, filterQuality: FilterQuality.medium);
      },
    );
  }
}
