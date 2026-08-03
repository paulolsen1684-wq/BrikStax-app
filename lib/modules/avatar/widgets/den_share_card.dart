// lib/modules/avatar/widgets/den_share_card.dart
// NOTE: DenShareCard intentionally uses fixed BT.* colors — the card is
// rendered into a PNG for external sharing and must always look consistent.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';

Future<bool> captureAndShareDen(
  GlobalKey boundaryKey, {
  String text = 'My LEGO collection, tracked with BrikStax 🧱',
}) async {
  try {
    final ro = boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return false;
    if (ro.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    final image = await ro.toImage(pixelRatio: 3.0);
    final bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return false;
    final png  = bytes.buffer.asUint8List();
    final file = XFile.fromData(png,
        mimeType: 'image/png', name: 'brikstax_den.png');
    await Share.shareXFiles([file], text: text);
    return true;
  } catch (_) {
    return false;
  }
}

class DenShareCard extends StatelessWidget {
  final Widget denView;
  final String title;
  const DenShareCard({
    super.key,
    required this.denView,
    this.title = 'My Den',
  });

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final col    = context.read<CollectionProvider>();
    final market = col.totalMarket;

    final themes = col.byTheme.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = themes.take(3).toList();

    // Fixed light colors — this card is always captured for sharing
    return Container(
      width: 360,
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Text('BRIKSTAX', style: BT.display(size: 22)),
              const Spacer(),
              const Text('🧱', style: TextStyle(fontSize: 20)),
            ]),
            Text(title.toUpperCase(),
                style: BT.mono(size: 10,
                    color: BT.ink.withOpacity(.6))),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          child: SizedBox(
            height: 260,
            child: Center(child: denView),
          ),
        ),

        Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
          decoration: BoxDecoration(
            color: BT.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: Row(children: [
            _stat(col.count.toString(), 'SETS'),
            _divider(),
            _stat(col.sealedCount.toString(), 'SEALED'),
            _divider(),
            _stat(market > 0 ? '\$${_fmt(market)}' : '—', 'MARKET',
                color: BT.green),
          ]),
        ),

        if (top.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Wrap(
              spacing: 7, runSpacing: 7,
              alignment: WrapAlignment.center,
              children: top.map((e) {
                final label = e.key.split(' > ').first;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BT.yellowBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BT.ink, width: 1.5),
                  ),
                  child: Text('$label · ${e.value}',
                      style: BT.mono(size: 9, color: BT.ink)),
                );
              }).toList(),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text('Track every brick',
                style: BT.mono(size: 9, color: BT.tx3)),
            Text('  ·  brikstax',
                style: BT.mono(size: 9, color: BT.gold)),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String value, String label, {Color? color}) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 6),
          child: Column(children: [
            Text(value,
                style: BT.display(size: 20, color: color ?? BT.ink),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label, style: BT.mono(size: 8, color: BT.tx3)),
          ]),
        ),
      );

  Widget _divider() =>
      Container(width: BT.bw, height: 44, color: BT.ink);
}
