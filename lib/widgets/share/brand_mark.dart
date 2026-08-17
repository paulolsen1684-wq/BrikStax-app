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
