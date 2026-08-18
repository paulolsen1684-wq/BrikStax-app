// lib/screens/set_share_screen.dart
//
// Share card for a single owned set -- cost paid and market value are
// personal financial info, so this defaults to showing ROI% only (a
// "+42% ROI" style headline) with a toggle to reveal the real dollar
// figures, rather than defaulting to exposing what someone paid the
// moment they post to Instagram. Same RepaintBoundary -> PNG -> share_plus
// capture pattern den_share_screen.dart already established, plus the
// optional photo-backdrop step shared with it and collection_share_screen.dart
// via widgets/share/photo_backdrop.dart.
//
// Four card variants, swiped between Instagram-Stories-style rather than
// picked via a button toggle (per explicit request): Classic (no photo),
// Classic + your photo, Product Photo (the set's own official image),
// Product Photo + your photo -- one continuous horizontal PageView, style
// and photo source no longer separate controls. A single _photo (once
// picked) is shared by both "+ your photo" variants. Product Photo
// (_ProductPhotoCard) is a dark, editorial "trading card" look built
// against a user-provided reference image, matched field-by-field after
// two earlier misses (wrong palette, then missing stats) -- see CLAUDE.md
// for that history. Real QR code (brikstax://set/<num>, handled by
// deep_link_service.dart) on both Product Photo variants, not a static logo.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/lego_set.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/share/photo_backdrop.dart';
import '../widgets/share/brand_mark.dart';

enum _Variant { classicPlain, classicPhoto, productOfficial, productPhoto }

const _variants = [
  _Variant.classicPlain, _Variant.classicPhoto,
  _Variant.productOfficial, _Variant.productPhoto,
];
const _variantLabels = [
  'Classic', 'Classic — Your Photo',
  'Product Photo', 'Product Photo — Your Photo',
];

class SetShareScreen extends StatefulWidget {
  final LegoSet set;
  const SetShareScreen({super.key, required this.set});
  @override State<SetShareScreen> createState() => _State();
}

class _State extends State<SetShareScreen> {
  final PageController _pageCtrl = PageController();
  final List<GlobalKey> _boundaryKeys = List.generate(4, (_) => GlobalKey());
  int _pageIndex = 0;
  bool _showDollars = false;
  File? _photo;
  ShareFormat _format = ShareFormat.story;
  bool _sharing = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final photo = await pickBackdropPhoto(context);
    if (photo != null) setState(() => _photo = photo);
  }

  // The two "+ Your Photo" variants need _photo before there's anything to
  // capture -- the action button becomes "Add a photo" instead of "Share"
  // on those pages until one's picked, rather than exporting a blank prompt.
  bool get _currentNeedsPhoto {
    final v = _variants[_pageIndex];
    return (v == _Variant.classicPhoto || v == _Variant.productPhoto) && _photo == null;
  }

  Future<void> _onActionTap() async {
    if (_currentNeedsPhoto) {
      await _pickPhoto();
      return;
    }
    await _share();
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    bool ok = false;
    try {
      final ro = _boundaryKeys[_pageIndex].currentContext?.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        if (ro.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 40));
        }
        final image = await ro.toImage(pixelRatio: 3.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final png = bytes.buffer.asUint8List();
          final file = XFile.fromData(png,
              mimeType: 'image/png', name: 'brikstax_set.png');
          await SharePlus.instance.share(ShareParams(
            files: [file],
            text: 'My ${widget.set.name}, tracked with BrikStax 🧱',
          ));
          ok = true;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _sharing = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Couldn\'t create the image — try again'),
      ));
    }
  }

  Widget _buildPage(int i, LegoSet s) {
    switch (_variants[i]) {
      case _Variant.classicPlain:
        return FixedRatioCanvas(
          format: _format,
          card: _SetShareCard(set: s, showDollars: _showDollars),
        );
      case _Variant.classicPhoto:
        if (_photo == null) {
          return _CanvasPrompt(
            format: _format,
            icon: Icons.add_a_photo_outlined,
            message: 'Add your own photo\nfor this card',
            onTap: _pickPhoto,
          );
        }
        return PhotoBackdropCard(
          photo: _photo,
          format: _format,
          scrim: false, // the slab is opaque -- supplies its own contrast
          card: _SlabSticker(set: s, showDollars: _showDollars),
        );
      case _Variant.productOfficial:
        if (s.imageUrl == null) {
          return _CanvasPrompt(
            format: _format,
            icon: Icons.image_not_supported_outlined,
            message: 'No product photo\navailable for this set',
          );
        }
        return _ProductPhotoCard(set: s, showDollars: _showDollars, format: _format);
      case _Variant.productPhoto:
        if (_photo == null) {
          return _CanvasPrompt(
            format: _format,
            icon: Icons.add_a_photo_outlined,
            message: 'Add your own photo\nfor this card',
            onTap: _pickPhoto,
          );
        }
        return _ProductPhotoCard(
          set: s, showDollars: _showDollars, format: _format, heroPhoto: _photo,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final s = widget.set;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: bt.surface,
            border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                      boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
                    ),
                    child: Icon(Icons.arrow_back_ios_new, color: bt.tx, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Share this set', style: BT.display(size: 24, color: bt.tx),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 14),
        // Instagram-Stories-style page dots -- also tappable to jump
        // straight to a variant instead of swiping through every one.
        _PageDots(
          count: 4, index: _pageIndex,
          onTap: (i) => _pageCtrl.animateToPage(i,
              duration: const Duration(milliseconds: 260), curve: Curves.easeOut),
        ),
        const SizedBox(height: 6),
        Text(_variantLabels[_pageIndex], style: BT.mono(size: 10, color: bt.tx3)),
        if (_photo != null) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: Text('Change photo', style: BT.mono(size: 9.5, color: bt.tx3)),
            ),
            Text('  ·  ', style: BT.mono(size: 9.5, color: bt.tx3)),
            GestureDetector(
              onTap: () => setState(() => _photo = null),
              child: Text('Remove photo', style: BT.mono(size: 9.5, color: bt.tx3)),
            ),
          ]),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Column(children: [
            _PillToggle(
              icon: _showDollars ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: _showDollars ? 'Hide \$ amounts' : 'Show \$ amounts',
              onTap: () => setState(() => _showDollars = !_showDollars),
            ),
            const SizedBox(height: 8),
            FormatToggle(format: _format, onChanged: (f) => setState(() => _format = f)),
          ]),
        ),

        // ── Swipeable card preview -- Instagram-Stories-style horizontal
        //    paging through the 4 variants. Each page keeps its own
        //    RepaintBoundary/key so _share() can capture whichever one is
        //    currently on screen without needing all 4 rendered at once.
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: 4,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (ctx, i) => Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RepaintBoundary(
                  key: _boundaryKeys[i],
                  child: _buildPage(i, s),
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('This image will be shared. Nothing here is posted for you automatically.',
              style: BT.mono(size: 9, color: BT.tx3), textAlign: TextAlign.center),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: GestureDetector(
              onTap: _sharing ? null : _onActionTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: BT.ink, width: BT.bw),
                  boxShadow: BT.shadow,
                ),
                child: _sharing
                    ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(BT.ink))))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(_currentNeedsPhoto ? Icons.add_a_photo_outlined : Icons.ios_share,
                            color: BT.ink, size: 20),
                        const SizedBox(width: 8),
                        Text(_currentNeedsPhoto ? 'Add a photo to continue' : 'Share this set',
                            style: BT.body(size: 16, color: BT.ink)),
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PillToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillToggle({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: bt.tx),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: BT.mono(size: 10, color: bt.tx),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

// ── Page dots: Instagram-Stories-style, also tappable to jump directly ──────
class _PageDots extends StatelessWidget {
  final int count;
  final int index;
  final ValueChanged<int> onTap;
  const _PageDots({required this.count, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: on ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: on ? BT.yellow : bt.cardBorder,
              borderRadius: BorderRadius.circular(4),
              border: on ? Border.all(color: BT.ink, width: 1.2) : null,
            ),
          ),
        );
      }),
    );
  }
}

// ── Canvas placeholder: shown on a "+ Your Photo" page before one's picked,
//    or on Product Photo when the set has no official image on file ───────
class _CanvasPrompt extends StatelessWidget {
  final ShareFormat format;
  final IconData icon;
  final String message;
  final VoidCallback? onTap;
  const _CanvasPrompt({
    required this.format,
    required this.icon,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: format.width,
      height: format.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: StudBackground(
        color: BT.cream,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: BT.white,
                shape: BoxShape.circle,
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadowSm,
              ),
              child: Icon(icon, size: 28, color: BT.ink),
            ),
            const SizedBox(height: 14),
            Text(message, style: BT.body(size: 14, color: BT.ink), textAlign: TextAlign.center),
            if (onTap != null) ...[
              const SizedBox(height: 6),
              Text('Tap to continue', style: BT.mono(size: 10, color: BT.tx3)),
            ],
          ]),
        ),
      ),
    ),
  );
}

// ── The composed share card (fixed BT.* colors -- always looks the same
//    regardless of the app's current theme, same rule den_share_card.dart
//    documents for its own card) ─────────────────────────────────────────────
class _SetShareCard extends StatelessWidget {
  final LegoSet set;
  final bool showDollars;
  const _SetShareCard({required this.set, required this.showDollars});

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roi = set.roi;
    final hasMoney = set.paid != null || set.ebayAvg != null;

    return Container(
      width: 460,
      decoration: BoxDecoration(
        color: BT.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BT.ink, width: BT.bw),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: double.infinity,
          color: BT.yellow,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: const Row(children: [BrikStaxMark(size: 30)]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 88, height: 88,
                color: BT.white,
                child: set.imageUrl != null
                    ? CachedNetworkImage(imageUrl: set.imageUrl!, fit: BoxFit.contain)
                    : const Center(child: Text('🧱', style: TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(set.name, style: BT.display(size: 17, color: BT.ink),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('#${set.num}', style: BT.mono(size: 11, color: BT.tx3)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: set.status == 'sealed' ? BT.greenBg : BT.yellowBg,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: set.status == 'sealed' ? BT.green : BT.gold, width: 1.5),
                ),
                child: Text(set.status == 'sealed' ? 'SEALED' : 'OPEN',
                    style: BT.mono(size: 9, color: BT.ink)),
              ),
            ])),
          ]),
        ),

        // ── ROI headline / stats ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: BT.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BT.ink, width: BT.bw),
            ),
            child: !hasMoney
                ? Text('No pricing data yet', style: BT.mono(size: 11, color: BT.tx3))
                : roi == null
                    ? (showDollars && set.ebayAvg != null
                        ? Text('\$${_fmt(set.ebayAvg!)} market value',
                            style: BT.display(size: 20, color: BT.ink))
                        : Text('🔒 Value hidden', style: BT.mono(size: 11, color: BT.tx3)))
                    : Column(children: [
                        Text(
                          '${roi >= 0 ? '▲' : '▼'} ${roi.abs().toStringAsFixed(0)}% ROI',
                          style: BT.display(size: 30,
                              color: roi >= 0 ? BT.green : BT.red),
                        ),
                        if (showDollars) ...[
                          const SizedBox(height: 10),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _dollarStat('PAID', set.paid),
                            Container(width: BT.bw, height: 30, color: BT.ink,
                                margin: const EdgeInsets.symmetric(horizontal: 14)),
                            _dollarStat('VALUE', set.ebayAvg, color: BT.green),
                          ]),
                        ],
                      ]),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Center(child: MadeWithBrikStax()),
        ),
      ]),
    );
  }

  Widget _dollarStat(String label, double? value, {Color? color}) => Column(children: [
    Text(value != null ? '\$${_fmt(value)}' : '—',
        style: BT.display(size: 16, color: color ?? BT.ink)),
    Text(label, style: BT.mono(size: 8, color: BT.tx3)),
  ]);
}

// ── Photo-backdrop sticker: PSA/StockX-style graded slab ────────────────────
// Borrows the actual visual language serious LEGO investors already use for
// sealed/graded sets -- a letter grade instead of a raw stat, cert-number
// styling using the set's own real number rather than a fake serial. Fully
// opaque so it supplies its own contrast against any photo (see scrim:false
// where this is used).
class _SlabSticker extends StatelessWidget {
  final LegoSet set;
  final bool showDollars;
  const _SlabSticker({required this.set, required this.showDollars});

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  static (String, Color) _grade(double? roi) {
    if (roi == null) return ('NR', BT.tx3);
    if (roi >= 100) return ('A+', BT.green);
    if (roi >= 50)  return ('A',  BT.green);
    if (roi >= 20)  return ('B+', BT.green);
    if (roi >= 0)   return ('B',  BT.gold);
    return ('C', BT.red);
  }

  @override
  Widget build(BuildContext context) {
    final (grade, gradeColor) = _grade(set.roi);
    final hasDollarPair = showDollars && set.paid != null && set.ebayAvg != null;

    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: BT.white,
        border: Border.all(color: BT.ink, width: BT.bw),
        borderRadius: BorderRadius.circular(10),
        boxShadow: BT.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              color: BT.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Text(grade, style: BT.display(size: 20, color: BT.yellow)),
            ),
            Container(width: BT.bw, color: BT.ink),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.name, style: BT.body(size: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      hasDollarPair
                          ? '\$${_fmt(set.paid!)} → \$${_fmt(set.ebayAvg!)}'
                          : 'CERT NO. ${set.num}',
                      style: BT.mono(size: 9, color: BT.tx3),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: BT.bw, color: BT.ink),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Text(
                set.roi != null
                    ? '${set.roi! >= 0 ? '+' : ''}${set.roi!.toStringAsFixed(0)}%'
                    : '—',
                style: BT.display(size: 17, color: gradeColor),
              ),
            ),
          ]),
        ),
        Container(
          width: double.infinity,
          color: BT.cream2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: const Center(child: MadeWithBrikStax(iconSize: 11)),
        ),
      ]),
    );
  }
}

// ── Product Photo card ────────────────────────────────────────────────────────
// Dark, editorial "trading card" look, matched field-by-field against a
// user-provided reference image after two earlier misses: v1 kept
// BrikStax's usual light cream card body when the reference is dark and
// moody (near-black photography, dark info panel, white text, gold/yellow
// reserved for the headline stat and brand mark only); v2 fixed the
// palette but still only showed a thin 2-cell Current-Value/Pieces row
// when the reference shows a fuller stacked list (Entry Price, Current
// Value, Status). Dark panel colors defined locally (not in BT, which is
// the light-cream/yellow "brick" palette used everywhere else).
//
// [heroPhoto] lets this same dark card use a user-uploaded photo instead
// of the set's own official image (set.imageUrl) -- style (this card's
// look) and photo source are independent choices, not fused; see
// SetShareScreen's _Variant list, which offers both as separate swipe
// pages. Falls back to set.imageUrl when heroPhoto is null.
class _ProductPhotoCard extends StatelessWidget {
  final LegoSet set;
  final bool showDollars;
  final ShareFormat format;
  final File? heroPhoto;
  const _ProductPhotoCard({
    required this.set,
    required this.showDollars,
    required this.format,
    this.heroPhoto,
  });

  static const _panelBg  = Color(0xFF111112);
  static const _txDim    = Color(0xFF9C9A96);
  // Brighter green/red than BT.green/BT.red -- those are tuned for text on
  // a light cream card and read muddy on a near-black panel. Reuses the
  // same dark-panel-safe pair collection_share_screen.dart's Glass sticker
  // already established, for consistency across every dark-background card.
  static const _greenDark = Color(0xFF4EE896);
  static const _redDark   = Color(0xFFFF8A80);

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roi = set.roi;
    final deepLink = 'brikstax://set/${set.num}';
    final photoHeight = format.height * .56;

    return Container(
      width: format.width,
      height: format.height,
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Hero photo -- fixed proportion, NOT Expanded ─────────────────
        SizedBox(
          height: photoHeight,
          child: Stack(fit: StackFit.expand, children: [
            if (heroPhoto != null)
              Image.file(heroPhoto!, fit: BoxFit.cover)
            else if (set.imageUrl != null)
              CachedNetworkImage(imageUrl: set.imageUrl!, fit: BoxFit.cover)
            else
              const ColoredBox(color: _panelBg, child: Center(
                child: Text('No photo available', style: TextStyle(color: _txDim)),
              )),
            // Top scrim so the pill/mark stay legible regardless of how
            // bright the product photo itself is.
            Positioned(
              top: 0, left: 0, right: 0, height: 80,
              child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(.55), Colors.transparent],
                ),
              )),
            ),
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.55),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(_statusLabel(set), style: BT.mono(size: 8.5, color: Colors.white)),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BT.ink, width: 1.2),
                ),
                child: const BrikStaxMark(size: 18),
              ),
            ),
          ]),
        ),

        // ── Dark info panel ───────────────────────────────────────────
        Expanded(
          child: Container(
            width: double.infinity,
            color: _panelBg,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(set.name, style: BT.display(size: 24, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${set.theme ?? "LEGO"} · #${set.num}',
                  style: BT.mono(size: 10.5, color: _txDim)),
              const SizedBox(height: 10),

              if (roi != null)
                Text('${roi >= 0 ? '▲' : '▼'} ${roi.abs().toStringAsFixed(1)}% ROI',
                    style: BT.display(size: 28, color: roi >= 0 ? _greenDark : _redDark))
              else if (showDollars && set.ebayAvg != null)
                Text('\$${_fmt(set.ebayAvg!)} value',
                    style: BT.display(size: 24, color: Colors.white))
              else
                Text('No pricing data yet', style: BT.mono(size: 11, color: _txDim)),
              const SizedBox(height: 12),

              // Stacked label:value list -- matches the density of the
              // reference's own example (Entry Price / Current Value /
              // Status), not the thin 2-cell row v2 shipped with. Minifigs
              // (set.minifigs, BrickSet's own field, verified live 2026-08-18)
              // added per explicit request, same extend-the-list treatment
              // as the other rows -- "Owned By" (BrickSet's community
              // ownership count) was considered but deliberately left out.
              if (set.paid != null)
                _statRow('Entry Price',
                    showDollars ? '\$${_fmt(set.paid!)}' : '🔒', muted: true),
              _statRow('Current Value', showDollars && set.ebayAvg != null
                  ? '\$${_fmt(set.ebayAvg!)}' : (set.ebayAvg != null ? '🔒' : '—')),
              _statRow('Status', _statusRowText(set), muted: true),
              if (set.minifigs != null)
                _statRow('Minifigs', '${set.minifigs}', muted: true),

              const Spacer(),

              // ── Scan row -- top divider, own band inside the dark panel
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white12, width: 1)),
                ),
                child: Row(children: [
                  const BrikStaxMark(size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Scan to view this set in BrikStax',
                      style: BT.mono(size: 8.5, color: _txDim))),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: QrImageView(
                      data: deepLink,
                      version: QrVersions.auto,
                      size: 38,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),

        // ── Yellow tagline band -- its own separate footer strip, not
        //    merged into the scan row.
        Container(
          width: double.infinity,
          color: BT.yellow,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Center(child: MadeWithBrikStax(textColor: BT.ink, iconSize: 12)),
        ),
      ]),
    );
  }

  static String _statusLabel(LegoSet s) {
    if (s.retired) return s.inRetirementWindow ? 'RETIRED · PRICE CLIMBING' : 'RETIRED';
    return s.status == 'sealed' ? 'ACTIVE · SEALED' : 'ACTIVE · OPEN';
  }

  // The Status stat row wants "Retired (2021)" style -- s.exitDate comes
  // straight from BrickSet's own exitDate field (already fetched for every
  // set on add, or backfilled by CollectionProvider's fill-missing-data
  // pass), so a real year is usually available, not fabricated.
  static String _statusRowText(LegoSet s) {
    if (s.retired) {
      final year = s.exitDate?.year;
      return year != null ? 'Retired ($year)' : 'Retired';
    }
    return s.status == 'sealed' ? 'Active · Sealed' : 'Active · Open';
  }

  // Stacked label:value row -- [muted] uses a smaller mono value style
  // (Entry Price, Status) so the one headline-worthy figure (Current
  // Value) is the only one competing visually with the ROI% above it.
  Widget _statRow(String label, String value, {bool muted = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label.toUpperCase(), style: BT.mono(size: 8.5, color: _txDim)),
      Text(value,
          style: muted
              ? BT.mono(size: 11, color: _txDim)
              : BT.display(size: 14, color: Colors.white)),
    ]),
  );
}
