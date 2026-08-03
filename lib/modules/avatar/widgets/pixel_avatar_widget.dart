// lib/modules/avatar/widgets/pixel_avatar_widget.dart
//
// Compositor for the ground-up pixel-art avatar spec: a fixed-width
// art-pixel body canvas (_canvasH varies by pass, see below) plus a hat
// overflow band above it, anchored to a single crown pixel.
//
// Vertical rhythm and every zone WIDTH went through several passes against
// real on-device renders before landing here:
//   1. Original spec (head:torso:legs 40:32:24, a 5:4:3 ratio) was written
//      before any asset existed and assumed each zone's raw canvas aspect
//      ratio told you the actual character content's shape -- it didn't;
//      the real files have a lot of transparent margin baked in around
//      the content (e.g. the head canvas is 1:1, but the actual head
//      silhouette inside it is ~0.78:1). All 20 assets got auto-cropped to
//      their real opaque bounding box (see git history/scratchpad for the
//      one-off crop script) to fix that.
//   2. Second pass (38:26:32) fixed legs reading as stubby doll-legs at
//      24 units, but overcorrected the head/hat -- still visually the
//      most dominant part of the figure once actually rendered, more so
//      than the reference art's chibi proportions called for.
//   3. Third pass (28:32:36) trimmed head further and grew both torso and
//      legs, but a real render still showed the head+hat block reading as
//      roughly a third of the figure's total height with a visibly narrow
//      torso/legs beneath it -- the previous passes only ever touched
//      HEIGHT, never WIDTH, and the hat/torso boxes were both still the
//      full 48-unit span, wider than they needed to be.
//   4. Fourth pass (20:34:42) cut head height again and, for the first
//      time, also narrowed head/hat/torso/legs WIDTH (was 22/48/48/32, now
//      18/38/44/30) so the whole figure reads narrower and taller rather
//      than short and wide. Hat band shrunk 20->14 and dip 7->5 to match
//      the now-smaller head. Direct response to "legs too small, torso too
//      small, head too big, hat too big" against a real render.
//   5. Fifth pass (16:36:44): the next render came back with head/hat no
//      longer flagged at all -- only "legs need to be larger and torso
//      needs to be larger." Took the remaining trim from head (20->16,
//      width 18->16) and funded torso/legs with it (34->36, 44->30->34
//      width; 42->44, 30->34 width). Hat band/dip scaled down
//      proportionally with head height (14->11, 5->4, width 38->34) so the
//      hat doesn't end up oversized relative to the smaller head -- it
//      wasn't touched based on new feedback, just kept in ratio.
//   6. Sixth pass (12:38:46): explicit instruction to double pass 5's own
//      deltas rather than wait for another screenshot -- so every change
//      from pass 4->5 was applied a second time on top of pass 5 (e.g.
//      head height 20->16 was -4, so this pass took it 16->12, another
//      -4). Confirmed against a real (rebuilt) render: head read
//      under-sized, as flagged as a risk when this pass landed.
//   7. This pass, HEIGHT only, widths untouched: torso confirmed as the
//      right size and left alone (38). Head was given an explicit target
//      (12->18) instead of a relative nudge. Legs got "a larger increase"
//      than the prior round's +2, so 46->50. Because torso didn't shrink
//      to fund head's growth, head+torso+legs no longer sums to the old
//      96 -- _canvasH grew to 106 (18+38+50) to absorb it; this is fine
//      because _canvasH is just a normalizing total (unit = size/_canvasH),
//      not a fixed physical constant, so the whole figure still renders at
//      exactly [size] tall regardless of what _canvasH is, only the
//      internal split changes. Hat band/dip scaled up with head height the
//      same way they scaled down in pass 5 (8->12, 3->5, proportional to
//      head's 12->18); hat width left alone since head width wasn't
//      touched this round.
//   8. This pass: "move the top half down by 6, increase head size by 5."
//      "Top half" is read the way a real minifig splits -- head+hat+torso
//      as one assembly, legs as the other -- so head+hat+torso shift down
//      by 6 units as a block, while legs stay exactly where they were.
//      Head grew +5 in BOTH dimensions (14x18 -> 19x23), not height-only
//      like pass 7, since this time the ask was "size" not a specific
//      axis. Torso's own top is still anchored flush to the (now lower,
//      now bigger) head, so its bottom moved down by 6+5=11 units total
//      without legs moving to compensate -- torso now genuinely overlaps
//      11 units into what used to be pure leg territory, for the first
//      time actually producing the "torso draws over the leg waistband"
//      effect this file's z-order comment has described since pass 1 but
//      no pass before this one had actually caused (torso and legs were
//      exactly flush, zero overlap, every prior pass). Hat band/dip/width
//      scaled up in the same proportion as head height/width grew (ratios
//      23/18 and 19/14) to stay sized correctly to the new head, same
//      standing rule as every prior pass that touched head size.
//   9. This pass: head +5% (19x23 -> 20x24, rounded from the exact 19.95/
//      24.15). Hat scaled up the same proportion again (15->16, width
//      41->43; dip's exact scale rounds back to 6, no change). Torso's top
//      is still anchored to topHalfTop + head height, so it drops another
//      unit with the taller head, deepening the pass-8 torso/leg overlap
//      by 1 unit. The other half of this request -- shifting the whole
//      figure left to make room for the equipped item -- isn't in this
//      file: see AvatarWidget's Align in avatar_widget.dart, since that's
//      about where the figure sits in the badge, not this widget's own
//      internal geometry.
//   10. This pass: "move the hat and head down by 4" -- narrower than pass
//       8's "top half" (which included torso). Torso is deliberately left
//       untouched this time, still anchored at the OLD topHalfTop+24
//       offset regardless of where head now sits, so head+hat get their
//       own _headHatDrop on top of _topHalfDrop rather than reusing it.
//       Head +5% again (20x24 -> 21x25.2). Hat -5% this time (the
//       opposite direction of head, an explicit override of the
//       "hat scales with head" convention every prior pass used) --
//       band 16->15.2, dip 6->5.7, width 43->40.85. Net effect: head's
//       bottom edge is now BELOW torso's top edge for the first time
//       (head grew+dropped while torso held still), so head now overlaps
//       down into the torso zone the same way torso started overlapping
//       legs in pass 8 -- and per the z-order rule already documented
//       below ("head draws over the torso collar"), head paints on top of
//       torso in that overlap, which is the intended effect, not a bug.
//   11. This pass: two changes, only one in this file. (a) "Move the head
//       layer behind the torso layer" -- swapped their order in the Stack,
//       so torso now paints over head in the pass-10 overlap zone instead
//       of the reverse; see the updated z-order note above. (b) "Move the
//       entire avatar left" and "increase size by 10%" turned out to
//       target a screen this file doesn't control -- avatar_editor.dart's
//       own preview panel builds PixelAvatarWidget directly, not through
//       AvatarWidget, so AvatarWidget's Align/size-multiplier changes from
//       earlier passes never reached it. Both fixes landed in
//       avatar_editor.dart's _preview() instead: see its own comments.
//   12. This pass: "move the hat down 5" (hat only, not head -- its own
//       _hatExtraDrop on top of _headHatDrop, same nested-offset pattern
//       as pass 10 introduced for head/torso) and "increase the item by
//       20%" (_itemW/_itemH 22x30 -> 26.4x36). Item's left/top are both
//       already formulas off _itemW/_itemH/_canvasW rather than literals,
//       so growing the constants alone keeps it correctly positioned
//       (still gapped off the canvas edge, still bottom-aligned with the
//       feet) with no other changes needed.
//   13. This pass: "move the hat down another 3" -- _hatExtraDrop 5->8, same
//       hat-only lever pass 12 introduced. The "increase preview size 25%"
//       half of this request isn't in this file either, same reason as
//       pass 11(b): it's avatar_editor.dart's own preview box/PixelAvatar-
//       Widget size, not this compositor's internal geometry.
//
// Head/torso/legs use BoxFit.fill rather than contain: with zone aspect
// now matching content aspect closely, fill guarantees both seam edges
// (neck, waist) touch exactly with no gap, at the cost of a barely-visible
// stretch on outlier items that deviate from their category's average
// ratio -- a better tradeoff than a visible gap breaking the figure apart.
// Hat stays on contain + bottomCenter, deliberately overlapping _hatDip
// units into the head zone rather than sitting exactly flush: hats drawn
// at an angle (a brim projecting down and to the side, matching the
// reference style) have their bounding-box bottom at the brim TIP, not at
// the part of the hat that actually sits near the hairline, so a flush
// anchor read as a gap above the head.
//
// Z-order (back to front): legs, head, torso, hat. Legs-under-everything and
// hat-over-everything are unchanged from the old sprite system's rule (legs
// draw first so torso covers the waistband, hat draws last so it covers
// hair). head/torso ordering flipped in pass 11 -- torso now paints OVER
// head in their pass-10 overlap zone, the opposite of the old "head draws
// over the torso collar so a hood/collar sits behind the face" rule (that
// rule is retired; torso art in this catalog doesn't have a collar/hood
// case that depended on it).
//
// Item (trophy/brick stack/watering can/toolbox) has no "held in hand" pose
// designed for this catalog, so it renders the same way ground accessories
// used to under the old sprite system: standing on the ground beside the
// figure, not composited onto it. It gets its own band to the right of the
// body canvas (_itemGap + _itemW wide, only added to the widget's total
// width when an item is actually equipped) rather than living inside
// _canvasW, so equipping/unequipping an item can't shift where the figure
// itself is drawn. Bottom-aligned with the legs' own bottom edge so it
// reads as standing on the same ground line as the feet.
//
// Per-layer animation: converted from Stateless to Stateful once the
// catalog got its first animated entries (legendary chrome gear's shine
// sweep, the X-Wing secret's engine flicker). A ticker is only allocated
// when at least one equipped/overridden cosmetic is actually isAnimated
// AND [animated] is true -- most avatars are all-static, so most instances
// of this widget never pay for one. Each layer picks its own frame off its
// OWN renderFrames.length against the same shared controller value, same
// "per-slot cadence, not one shared frame counter" principle
// SpriteAvatarWidget used (see den_scene.dart's _accFrame comment for why
// that matters: a 4-frame item and an 8-frame item both need to read as
// evenly-paced, not one skipping steps to match the other's count).
import 'package:flutter/material.dart';
import '../data/pixel_cosmetics.dart';

class PixelAvatarState {
  final String? headId;
  final String? hatId;
  final String? torsoId;
  final String? legsId;
  final String? itemId;
  const PixelAvatarState({
    this.headId,
    this.hatId,
    this.torsoId,
    this.legsId,
    this.itemId,
  });
}

class PixelAvatarWidget extends StatefulWidget {
  final PixelAvatarState state;
  /// Display height of the 64x96 body canvas (excludes the hat overflow
  /// band, which renders above this -- the widget's total footprint is
  /// taller than [size] by the overflow band's own height).
  final double size;
  /// Optional id -> PixelCosmetic overrides, checked before the real
  /// catalog (pixelCosmeticsById). Every normal call site leaves this null
  /// and gets the real catalog data. PixelItemTunerScreen is the one
  /// exception: it passes a live-edited copy of whichever cosmetic is
  /// currently being tuned (via PixelCosmetic.copyWith) so its offset/scale
  /// changes preview immediately, without mutating the actual const catalog
  /// (which can't be mutated at runtime anyway).
  final Map<String, PixelCosmetic>? overrides;
  /// Whether animated cosmetics (see PixelCosmetic.isAnimated) actually
  /// cycle frames. Defaults true -- this widget is usually a living avatar
  /// preview, not a captured snapshot; callers that want a static frame
  /// (e.g. a share-card screenshot) pass false explicitly.
  final bool animated;
  const PixelAvatarWidget({
    super.key,
    required this.state,
    this.size = 192,
    this.overrides,
    this.animated = true,
  });

  static const double _canvasW = 64, _canvasH = 106, _hatBandH = 15.2;
  // Public alias so external code (PixelItemTunerScreen) can convert its
  // own screen-pixel drag deltas into the same "unit" system offsetX/
  // offsetY/scale are expressed in: unit = previewSize / canvasHeightUnits.
  static const double canvasHeightUnits = _canvasH;
  // How far the hat's box is allowed to dip into the head zone -- see the
  // comment on the hat Positioned below. Generous on purpose: better to
  // slightly over-cover hair than leave a visible gap, and it's an easy
  // single number to dial back once real devices confirm it.
  static const double _hatDip = 5.7;
  // How far the head+hat+torso assembly ("top half," see pass 8) sits
  // below topPad -- legs are NOT offset by this, only head/hat/torso.
  static const double _topHalfDrop = 6;
  // Additional drop for head+hat ONLY, on top of _topHalfDrop -- torso
  // does NOT get this (see pass 10), which is what lets head start
  // overlapping down into the torso zone instead of moving together.
  static const double _headHatDrop = 4;
  // Additional drop for HAT ONLY, on top of _headHatDrop -- head does not
  // get this one, see pass 12 (5) and pass 13 (+3 more, 5->8).
  static const double _hatExtraDrop = 8;
  // Item band: gap from the body canvas edge, then the item's own box.
  // Only added to the widget's total width when an item is equipped -- see
  // the file header comment for why this lives outside _canvasW.
  static const double _itemGap = 4, _itemW = 26.4, _itemH = 36;

  @override
  State<PixelAvatarWidget> createState() => _PixelAvatarWidgetState();
}

class _PixelAvatarWidgetState extends State<PixelAvatarWidget>
    with TickerProviderStateMixin {
  // TickerProviderStateMixin (plural), NOT SingleTickerProviderStateMixin --
  // the latter only permits creating a ticker ONCE per State's entire
  // lifetime; disposing the old AnimationController does not release that
  // slot (the mixin never clears its internal reference). _syncTicker below
  // disposes-and-recreates whenever the animated/static status changes --
  // e.g. switching between an animated and a static item in
  // PixelItemTunerScreen -- which is exactly the pattern that throws
  // "SingleTickerProviderStateMixin can only be used as a TickerProvider
  // once" under the Single variant. Cost of the plural mixin is trivial
  // (a Set instead of a single field); this widget only ever holds 0 or 1
  // ticker at a time regardless.
  AnimationController? _ctrl;

  PixelCosmetic? _resolve(String? id) => id == null
      ? null
      : (widget.overrides?[id] ?? pixelCosmeticsById[id]);

  bool _anyAnimated() => [
    _resolve(widget.state.headId), _resolve(widget.state.hatId),
    _resolve(widget.state.torsoId), _resolve(widget.state.legsId),
    _resolve(widget.state.itemId),
  ].any((c) => c?.isAnimated ?? false);

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant PixelAvatarWidget old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  // Ticker is allocated/disposed on demand rather than always running --
  // most avatars equip nothing animated, so most instances of this widget
  // never pay for one. 900ms matches the old SpriteAvatarWidget's cadence
  // (see den_scene.dart's _accFrame comment for why other animated layers
  // in this app already sync to that number).
  void _syncTicker() {
    final needed = widget.animated && _anyAnimated();
    if (needed && _ctrl == null) {
      _ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 900))
        ..addListener(() => setState(() {}))
        ..repeat();
    } else if (!needed && _ctrl != null) {
      _ctrl!.dispose();
      _ctrl = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  String _frameAsset(PixelCosmetic c) {
    final frames = c.renderFrames;
    // Was `return c.assetPath` -- broke the tuner's frame stepper: pausing
    // sends an override with frames: [renderFrames[_manualFrame]] (a
    // single-element list holding whichever frame was picked), but c
    // .assetPath on that override is always the ORIGINAL frame 1's path,
    // unchanged by copyWith. So stepping to any other frame rendered frame
    // 1 regardless of which one was selected. frames.first is the actual
    // single frame in play here (and equals assetPath in the untouched,
    // non-paused case, so this changes nothing for normal playback).
    if (frames.length <= 1 || _ctrl == null) return frames.first;
    final i = (_ctrl!.value * frames.length).floor().clamp(0, frames.length - 1);
    return frames[i];
  }

  // Renders one layer at its shared slot geometry (baseLeft/baseTop already
  // in px, baseW/baseH in units), then applies the cosmetic's own
  // offsetX/offsetY/scale on top -- scale expands from the box's own
  // center (not its top-left corner) so nudging scale up/down in the tuner
  // doesn't also silently drag the item sideways. Picks the current
  // animation frame (if any) off the SAME shared controller value each
  // layer's own renderFrames.length applies to independently.
  Widget _layer(PixelCosmetic c, double unit, {
    required double baseLeft, required double baseTop,
    required double baseWUnits, required double baseHUnits,
    required BoxFit fit, Alignment alignment = Alignment.center,
  }) {
    final baseW = baseWUnits * unit;
    final baseH = baseHUnits * unit;
    final w = baseW * c.scale;
    final h = baseH * c.scale;
    final left = baseLeft - (w - baseW) / 2 + c.offsetX * unit;
    final top  = baseTop  - (h - baseH) / 2 + c.offsetY * unit;
    return Positioned(
      left: left, top: top, width: w, height: h,
      child: Image.asset(_frameAsset(c),
          fit: fit, alignment: alignment, filterQuality: FilterQuality.medium),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final unit = size / PixelAvatarWidget._canvasH;
    final topPad = PixelAvatarWidget._hatBandH * unit;
    final topHalfTop = topPad + PixelAvatarWidget._topHalfDrop * unit;
    final headHatTop = topHalfTop + PixelAvatarWidget._headHatDrop * unit;

    final head  = _resolve(widget.state.headId);
    final hat   = _resolve(widget.state.hatId);
    final torso = _resolve(widget.state.torsoId);
    final legs  = _resolve(widget.state.legsId);
    final item  = _resolve(widget.state.itemId);

    final totalW = PixelAvatarWidget._canvasW +
        (item != null ? PixelAvatarWidget._itemGap + PixelAvatarWidget._itemW : 0);

    return ClipRect(
      child: SizedBox(
        width: totalW * unit,
        height: topPad + size,
        child: Stack(children: [
          if (legs != null)
            _layer(legs, unit,
                baseLeft: 13 * unit, baseTop: topPad + 56 * unit,
                baseWUnits: 38, baseHUnits: 50, fit: BoxFit.fill),
          if (head != null)
            _layer(head, unit,
                baseLeft: 21.5 * unit, baseTop: headHatTop,
                baseWUnits: 21, baseHUnits: 25.2, fit: BoxFit.fill),
          if (torso != null)
            // Top is anchored flush beneath the (now-lower, now-bigger)
            // head -- topHalfTop + head's own height, not a fixed offset --
            // so torso genuinely overlaps down into leg territory when the
            // top half drops or the head grows. See pass 8. Painted AFTER
            // head (pass 11) so torso draws OVER head in their pass-10
            // overlap zone -- the opposite of the "head draws over the
            // torso collar" rule this file used to follow; that rule is
            // retired for this pair, see the z-order note below.
            _layer(torso, unit,
                baseLeft: 8 * unit, baseTop: topHalfTop + 24 * unit,
                baseWUnits: 48, baseHUnits: 38, fit: BoxFit.fill),
          if (hat != null)
            // Bottom edge deliberately overlaps _hatDip units into the head
            // zone rather than sitting exactly flush at headHatTop -- hats
            // drawn at an angle (a brim projecting down and to the side,
            // matching the reference style) have their bounding-box bottom
            // at the brim TIP, not at the part of the hat that actually
            // sits near the hairline. Anchoring flush to that bounding box
            // pushed the whole hat up, reading as a gap above the head.
            // This was in the original spec (a "brim overlap allowance")
            // but got dropped when this widget was first built --
            // restoring it here instead of re-deriving it. Anchored off
            // headHatTop (not topHalfTop) so the hat rides down with the
            // head, independent of torso -- see pass 10. Plus
            // _hatExtraDrop on top of that, hat-only -- see pass 12.
            _layer(hat, unit,
                baseLeft: 11.575 * unit,
                baseTop: headHatTop - PixelAvatarWidget._hatBandH * unit +
                    PixelAvatarWidget._hatExtraDrop * unit,
                baseWUnits: 40.85,
                baseHUnits: PixelAvatarWidget._hatBandH + PixelAvatarWidget._hatDip,
                fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          if (item != null)
            // Bottom-aligned with the legs' own bottom edge (topPad +
            // canvasH*unit, i.e. the same ground line the feet stand on)
            // rather than the item box's own top -- items are various
            // aspect ratios and shouldn't all read as floating at
            // different heights.
            _layer(item, unit,
                baseLeft: (PixelAvatarWidget._canvasW + PixelAvatarWidget._itemGap) * unit,
                baseTop: topPad + (PixelAvatarWidget._canvasH - PixelAvatarWidget._itemH) * unit,
                baseWUnits: PixelAvatarWidget._itemW, baseHUnits: PixelAvatarWidget._itemH,
                fit: BoxFit.contain, alignment: Alignment.bottomCenter),
        ]),
      ),
    );
  }
}
