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
// Three photo sources, added 2026-08-17 (_PhotoSource): none (the plain
// card on FixedRatioCanvas), mine (user-uploaded photo, the original
// PhotoBackdropCard/_SlabSticker sticker flow), and product (the set's own
// official product photo as full-bleed hero art -- no upload needed, works
// even with no photo of your own). "Product" was designed against a
// user-provided reference mockup and includes a real QR code
// (brikstax://set/<num>, handled by deep_link_service.dart) rather than
// a static logo, confirmed with the user before building.
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

enum _PhotoSource { none, mine, product }

class SetShareScreen extends StatefulWidget {
  final LegoSet set;
  const SetShareScreen({super.key, required this.set});
  @override State<SetShareScreen> createState() => _State();
}

class _State extends State<SetShareScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _showDollars = false;
  File? _photo;
  _PhotoSource _source = _PhotoSource.none;
  ShareFormat _format = ShareFormat.story;
  bool _sharing = false;

  Future<void> _pickPhoto() async {
    final photo = await pickBackdropPhoto(context);
    if (photo != null) setState(() { _photo = photo; _source = _PhotoSource.mine; });
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    bool ok = false;
    try {
      final ro = _boundaryKey.currentContext?.findRenderObject();
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

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            // Privacy toggle
            _PillToggle(
              icon: _showDollars ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              label: _showDollars ? 'Hide \$ amounts' : 'Show \$ amounts',
              onTap: () => setState(() => _showDollars = !_showDollars),
            ),
            const SizedBox(height: 8),

            // Backdrop source -- no photo (plain card), your own upload, or
            // the set's real product photo as automatic hero art. Product
            // is disabled when the set has no image on file (nothing to
            // show), rather than silently falling back to something else.
            _SourceToggle(
              source: _source,
              hasProductImage: s.imageUrl != null,
              onChanged: (src) async {
                // Only launches the picker the first time -- once a photo's
                // already been picked, re-selecting "Mine" just switches
                // back to showing it rather than forcing a fresh pick.
                if (src == _PhotoSource.mine && _photo == null) {
                  await _pickPhoto();
                } else {
                  setState(() => _source = src);
                }
              },
            ),
            if (_source == _PhotoSource.mine) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickPhoto,
                child: Text('Change photo', style: BT.mono(size: 10, color: bt.tx3)),
              ),
            ],
            const SizedBox(height: 12),

            FormatToggle(format: _format, onChanged: (f) => setState(() => _format = f)),
            const SizedBox(height: 16),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: switch (_source) {
                  _PhotoSource.none => FixedRatioCanvas(
                      format: _format,
                      card: _SetShareCard(set: s, showDollars: _showDollars),
                    ),
                  _PhotoSource.mine => PhotoBackdropCard(
                      photo: _photo,
                      format: _format,
                      scrim: false, // the slab is opaque -- supplies its own contrast
                      card: _SlabSticker(set: s, showDollars: _showDollars),
                    ),
                  _PhotoSource.product => _ProductPhotoCard(
                      set: s, showDollars: _showDollars, format: _format,
                    ),
                },
              ),
            ),

            const SizedBox(height: 12),
            Text('This image will be shared. Nothing here is posted for you automatically.',
                style: BT.mono(size: 9, color: BT.tx3), textAlign: TextAlign.center),
          ]),
        )),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: GestureDetector(
              onTap: _sharing ? null : _share,
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
                        const Icon(Icons.ios_share, color: BT.ink, size: 20),
                        const SizedBox(width: 8),
                        Text('Share this set', style: BT.body(size: 16, color: BT.ink)),
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

// ── Backdrop source: none / mine / product ────────────────────────────────
class _SourceToggle extends StatelessWidget {
  final _PhotoSource source;
  final bool hasProductImage;
  final ValueChanged<_PhotoSource> onChanged;
  const _SourceToggle({
    required this.source,
    required this.hasProductImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    Widget seg(_PhotoSource s, String label, {bool enabled = true}) {
      final on = source == s;
      return Expanded(child: GestureDetector(
        onTap: enabled ? () => onChanged(s) : null,
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: on ? BT.yellow : bt.cardBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: on ? BT.ink : bt.cardBorder, width: BT.bw),
              boxShadow: on ? null : [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
            ),
            child: Text(label, textAlign: TextAlign.center,
                style: BT.mono(size: 10, color: on ? BT.ink : bt.tx)),
          ),
        ),
      ));
    }
    return Row(children: [
      seg(_PhotoSource.none, 'No photo'),
      const SizedBox(width: 8),
      seg(_PhotoSource.mine, 'My photo'),
      const SizedBox(width: 8),
      seg(_PhotoSource.product, 'Product photo', enabled: hasProductImage),
    ]);
  }
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
// Uses the set's own official product image (from Rebrickable/BrickSet,
// already fetched into set.imageUrl for every set) as full-bleed hero art --
// no upload required, works even for a user with no photo of their own.
// Designed against a user-provided reference mockup: photo up top with a
// status pill and the logo mark overlaid, a solid info card below with a
// real "scan to view in BrikStax" QR code (brikstax://set/<num>, handled by
// deep_link_service.dart) rather than a static graphic.
//
// Unlike PhotoBackdropCard's stickers (a small capped-height overlay meant
// to leave most of an arbitrary personal photo visible), this card is the
// dominant visual on purpose -- the "photo" here is curated product
// photography, not a personal snapshot, so there's no "don't cover it up"
// concern to design around. Built as its own Column (photo Expanded, card
// content fixed) rather than reusing PhotoBackdropCard's Stack+scrim
// approach, since the proportions and layout are fundamentally different.
class _ProductPhotoCard extends StatelessWidget {
  final LegoSet set;
  final bool showDollars;
  final ShareFormat format;
  const _ProductPhotoCard({required this.set, required this.showDollars, required this.format});

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roi = set.roi;
    final deepLink = 'brikstax://set/${set.num}';

    return Container(
      width: format.width,
      height: format.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Hero photo ────────────────────────────────────────────────
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            set.imageUrl != null
                ? CachedNetworkImage(imageUrl: set.imageUrl!, fit: BoxFit.cover)
                : Container(color: BT.cream2),
            // Subtle top scrim so the pill/mark stay legible regardless
            // of how bright the product photo itself is.
            Positioned(
              top: 0, left: 0, right: 0, height: 90,
              child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(.45), Colors.transparent],
                ),
              )),
            ),
            Positioned(
              top: 14, left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.55),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(_statusLabel(set), style: BT.mono(size: 9, color: Colors.white)),
              ),
            ),
            const Positioned(top: 14, right: 14, child: BrikStaxMark(size: 26)),
          ]),
        ),

        // ── Info card ─────────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: BT.cream,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(set.name, style: BT.display(size: 22, color: BT.ink),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${set.theme ?? "LEGO"} · #${set.num}',
                style: BT.mono(size: 11, color: BT.tx3)),
            const SizedBox(height: 10),

            if (roi != null)
              Text('${roi >= 0 ? '▲' : '▼'} ${roi.abs().toStringAsFixed(1)}% ROI',
                  style: BT.display(size: 26, color: roi >= 0 ? BT.green : BT.red))
            else
              Text('No pricing data yet', style: BT.mono(size: 11, color: BT.tx3)),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: BT.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BT.ink, width: 1.5),
              ),
              child: Row(children: [
                _statCell(showDollars && set.ebayAvg != null
                    ? '\$${_fmt(set.ebayAvg!)}' : (set.ebayAvg != null ? '🔒' : '—'),
                    'CURRENT VALUE'),
                Container(width: 1.5, height: 38, color: BT.ink),
                _statCell(set.pieces?.toString() ?? '—', 'PIECES'),
              ]),
            ),
            const SizedBox(height: 12),

            Row(children: [
              const BrikStaxMark(size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text('Scan to view in BrikStax',
                  style: BT.mono(size: 9, color: BT.tx3))),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: BT.white,
                  border: Border.all(color: BT.ink, width: 1.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: QrImageView(
                  data: deepLink,
                  version: QrVersions.auto,
                  size: 40,
                  backgroundColor: BT.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: BT.ink),
                  dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square, color: BT.ink),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  static String _statusLabel(LegoSet s) {
    if (s.retired) return s.inRetirementWindow ? 'RETIRED · PRICE CLIMBING' : 'RETIRED';
    return s.status == 'sealed' ? 'ACTIVE · SEALED' : 'ACTIVE · OPEN';
  }

  Widget _statCell(String value, String label) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      child: Column(children: [
        Text(value, style: BT.display(size: 16, color: BT.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 1),
        Text(label, style: BT.mono(size: 7.5, color: BT.tx3)),
      ]),
    ),
  );
}
