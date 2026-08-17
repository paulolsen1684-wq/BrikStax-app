// lib/widgets/share/brand_mark.dart
//
// The actual BrikStax logo, used in place of the plain Text('BRIKSTAX') +
// emoji combo every share card's header used before this. The source image
// (assets/brand/brikstax_mark.png, user-provided) has "BRIK STAX" lettering
// baked into the badge art itself, so this replaces the whole wordmark
// treatment wherever it's used, not just the emoji next to it -- the emoji
// alone was the original complaint, but keeping a separate Text('BRIKSTAX')
// beside a logo that already spells out the name would just show the brand
// name twice in the same spot.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BrikStaxMark extends StatelessWidget {
  final double size;
  const BrikStaxMark({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/brikstax_mark.png',
    width: size,
    height: size,
  );
}

/// The standardized bottom-of-image credit line, icon + text together --
/// replaces every card's own previously-inconsistent footer text ("Track
/// every brick · brikstax", the Slab's "BRIKSTAX AUTHENTICATED · TRACK
/// EVERY BRICK", or nothing at all on Collection's glass panel/Den's
/// minimal sticker). [textColor] needs to be passed per context since this
/// shows up against very different backgrounds -- a white card, a cream
/// footer bar, a translucent glass panel, or straight on a photo.
class MadeWithBrikStax extends StatelessWidget {
  final Color textColor;
  final double iconSize;
  const MadeWithBrikStax({super.key, this.textColor = BT.tx3, this.iconSize = 13});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BrikStaxMark(size: iconSize),
      const SizedBox(width: 6),
      Text('Made with BrikStax', style: BT.mono(size: 9, color: textColor)),
    ],
  );
}
