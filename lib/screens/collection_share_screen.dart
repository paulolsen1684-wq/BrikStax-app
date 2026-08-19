// lib/screens/collection_share_screen.dart
//
// Share card for the whole collection, OR a filtered view of it -- entry
// point lives on the Inventory screen (inventory.dart's share icon), which
// passes [scopedSets]/[scopedLabel] whenever a theme/condition/search
// filter is active there ("My Star Wars Collection" computed from just
// those sets, not the whole thing). No filter active -> both params are
// null and this reads the whole CollectionProvider, same as before this
// scoping existed. Moved here from a short-lived Dashboard-hero placement
// (see CLAUDE.md) after user feedback that Inventory -- where you're
// already looking at a specific set of sets -- makes more sense than a
// flat "always the whole collection" button elsewhere.
//
// Total ROI% is always shown (it's a percentage, not a dollar figure), but
// total cost paid and total market value default to hidden, same privacy
// stance as set_share_screen.dart, with a toggle to reveal them. Same
// RepaintBoundary -> PNG -> share_plus capture pattern den_share_screen.dart
// established, plus the optional photo-backdrop step shared with it and
// set_share_screen.dart via widgets/share/photo_backdrop.dart.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/collection.dart';
import '../models/lego_set.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/share/photo_backdrop.dart';
import '../widgets/share/brand_mark.dart';

/// The set of sets being shared, plus what to call it -- computed once from
/// either an explicit filtered list (Inventory screen, filter active) or
/// the whole collection (no filter, or reached some other way). Mirrors
/// CollectionProvider's own aggregate formulas (portfolioRoi/topGainers/
/// byTheme) but over an arbitrary subset instead of always everything.
class _ShareScope {
  final String label;
  final List<LegoSet> sets;
  const _ShareScope({required this.label, required this.sets});

  int get count => sets.length;
  int get sealedCount => sets.where((s) => s.status == 'sealed').length;
  double get totalMarket => sets.fold(0.0, (a, s) => a + (s.ebayAvg ?? 0));
  double get _totalEffective =>
      sets.fold(0.0, (a, s) => a + (s.effectivePaid ?? s.paid ?? 0));

  double? get roi {
    final basis = _totalEffective;
    if (basis == 0 || totalMarket == 0) return null;
    return (totalMarket - basis) / basis * 100;
  }

  List<LegoSet> get topGainers {
    final priced = sets.where((s) => s.roi != null).toList()
      ..sort((a, b) => b.roi!.compareTo(a.roi!));
    return priced.take(3).toList();
  }

  Map<String, int> get byTheme {
    final map = <String, int>{};
    for (final s in sets) {
      final t = s.theme?.split(' > ').first ?? 'Unknown';
      map[t] = (map[t] ?? 0) + 1;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }
}

class CollectionShareScreen extends StatefulWidget {
  final List<LegoSet>? scopedSets;
  final String? scopedLabel;
  const CollectionShareScreen({super.key, this.scopedSets, this.scopedLabel});
  @override State<CollectionShareScreen> createState() => _State();
}

class _State extends State<CollectionShareScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _showDollars = false;
  File? _photo;
  ShareFormat _format = ShareFormat.story;
  bool _sharing = false;

  Future<void> _pickPhoto() async {
    final photo = await pickBackdropPhoto(context, format: _format);
    if (photo != null) setState(() => _photo = photo);
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
              mimeType: 'image/png', name: 'brikstax_collection.png');
          await SharePlus.instance.share(ShareParams(
            files: [file],
            text: 'My LEGO collection, tracked with BrikStax 🧱',
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
    final scope = widget.scopedSets != null
        ? _ShareScope(label: widget.scopedLabel ?? 'My Collection', sets: widget.scopedSets!)
        : _ShareScope(label: 'My Collection', sets: context.watch<CollectionProvider>().sets);

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
                Expanded(child: Text(
                    widget.scopedSets != null ? 'Share "${scope.label}"' : 'Share your collection',
                    style: BT.display(size: 22, color: bt.tx),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              Expanded(child: _PillToggle(
                icon: _showDollars ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                label: _showDollars ? 'Hide \$ amounts' : 'Show \$ amounts',
                onTap: () => setState(() => _showDollars = !_showDollars),
              )),
              const SizedBox(width: 8),
              Expanded(child: _PillToggle(
                icon: _photo == null ? Icons.add_a_photo_outlined : Icons.sync_outlined,
                label: _photo == null ? 'Add a photo' : 'Change photo',
                onTap: _pickPhoto,
              )),
            ]),
            if (_photo != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _photo = null),
                child: Text('Remove photo', style: BT.mono(size: 10, color: bt.tx3)),
              ),
            ],
            const SizedBox(height: 12),

            FormatToggle(format: _format, onChanged: (f) => setState(() => _format = f)),
            const SizedBox(height: 16),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: _photo == null
                    ? FixedRatioCanvas(
                        format: _format,
                        card: _CollectionShareCard(scope: scope, showDollars: _showDollars),
                      )
                    : PhotoBackdropCard(
                        photo: _photo,
                        format: _format,
                        scrim: false, // the glass panel supplies its own contrast via blur
                        card: _GlassSticker(scope: scope, showDollars: _showDollars),
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Text('This image will be shared. Your stats update automatically.',
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
                        Text('Share my collection', style: BT.body(size: 16, color: BT.ink)),
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

// ── The composed share card (fixed BT.* colors, same rule den_share_card.dart
//    documents -- always looks the same regardless of the app's theme) ────────
class _CollectionShareCard extends StatelessWidget {
  final _ShareScope scope;
  final bool showDollars;
  const _CollectionShareCard({required this.scope, required this.showDollars});

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roi = scope.roi;
    final themes = scope.byTheme.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThemes = themes.take(3).toList();
    final topGainers = scope.topGainers.take(3).toList();

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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BrikStaxMark(size: 32),
            const SizedBox(height: 4),
            Text(scope.label.toUpperCase(), style: BT.mono(size: 10, color: BT.ink.withOpacity(.6))),
          ]),
        ),

        // ── Headline ROI ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: BT.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BT.ink, width: BT.bw),
            ),
            child: roi == null
                ? Text('Building my collection', style: BT.mono(size: 11, color: BT.tx3))
                : Text(
                    '${roi >= 0 ? '▲' : '▼'} ${roi.abs().toStringAsFixed(0)}% ROI',
                    style: BT.display(size: 30, color: roi >= 0 ? BT.green : BT.red),
                  ),
          ),
        ),

        // ── Stats row ─────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          decoration: BoxDecoration(
            color: BT.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: Row(children: [
            _stat(scope.count.toString(), 'SETS'),
            _divider(),
            _stat(scope.sealedCount.toString(), 'SEALED'),
            _divider(),
            _stat(showDollars
                ? (scope.totalMarket > 0 ? '\$${_fmt(scope.totalMarket)}' : '—')
                : '🔒', 'MARKET', color: BT.green),
          ]),
        ),

        // ── Top gainers (ROI% only -- no dollar figures, safe to always
        //    show) ─────────────────────────────────────────────────────────
        if (topGainers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(children: topGainers.map((s) => _gainerRow(s)).toList()),
          ),

        if (topThemes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Wrap(
              spacing: 7, runSpacing: 7, alignment: WrapAlignment.center,
              children: topThemes.map((e) {
                final label = e.key.split(' > ').first;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BT.yellowBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BT.ink, width: 1.5),
                  ),
                  child: Text('$label · ${e.value}', style: BT.mono(size: 9, color: BT.ink)),
                );
              }).toList(),
            ),
          ),

        const Padding(
          padding: EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Center(child: MadeWithBrikStax()),
        ),
      ]),
    );
  }

  Widget _gainerRow(LegoSet s) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: BT.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: BT.ink, width: 1.5),
    ),
    child: Row(children: [
      const Text('📈', style: TextStyle(fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(child: Text(s.name, style: BT.body(size: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: BT.greenBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: BT.green, width: 1.5),
        ),
        child: Text('+${s.roi!.toStringAsFixed(0)}%', style: BT.mono(size: 8, color: BT.ink)),
      ),
    ]),
  );

  Widget _stat(String value, String label, {Color? color}) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(children: [
        Text(value, style: BT.display(size: 20, color: color ?? BT.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: BT.mono(size: 8, color: BT.tx3)),
      ]),
    ),
  );

  Widget _divider() => Container(width: BT.bw, height: 44, color: BT.ink);
}

// ── Photo-backdrop sticker: Strava-style frosted glass panel ────────────────
// A real material departure from BrikStax's usual hard-ink-border "brick"
// language everywhere else in the app -- deliberate for this one spot, since
// a translucent blurred panel reads as part of the photo rather than a card
// stuck on top of it, and supplies its own contrast without needing the
// scrim (see scrim:false where this is used).
class _GlassSticker extends StatelessWidget {
  final _ShareScope scope;
  final bool showDollars;
  const _GlassSticker({required this.scope, required this.showDollars});

  static String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final roi = scope.roi;
    final roiColor = roi == null
        ? Colors.white
        : (roi >= 0 ? const Color(0xFF4EE896) : const Color(0xFFFF8A80));
    final roiText = roi == null
        ? '—'
        : '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(0)}%'
          '${showDollars && scope.totalMarket > 0 ? ' · \$${_fmt(scope.totalMarket)}' : ''}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 460,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.4), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // No logo mark up here -- the standardized footer below already
            // carries the icon + "Made with BrikStax", so this stays plain
            // text to avoid showing the mark twice on one panel.
            Text(scope.label.toUpperCase(),
                style: BT.mono(size: 9, color: Colors.white.withOpacity(.85)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              _glassStat(scope.count.toString(), 'SETS'),
              _glassStat(scope.sealedCount.toString(), 'SEALED'),
              _glassStat(roiText, 'ROI', valueColor: roiColor),
            ]),
            const SizedBox(height: 12),
            Center(child: MadeWithBrikStax(
                textColor: Colors.white.withOpacity(.8), iconSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _glassStat(String value, String label, {Color valueColor = Colors.white}) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: BT.display(size: 17, color: valueColor),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(label, style: BT.mono(size: 7, color: Colors.white.withOpacity(.7))),
    ]),
  );
}
