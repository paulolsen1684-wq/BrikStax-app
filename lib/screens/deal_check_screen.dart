// lib/screens/deal_check_screen.dart
//
// Deal Check — scan/enter a set in-store, type the sticker price, and see how
// much off retail it is, with a tiered celebration (OK / Decent / Great).
//
// GATED: this whole feature is dormant until kScannerLive flips true (see
// lib/services/verified.dart). The wishlist button that opens it is wrapped in
// `if (kScannerLive)`, so nothing appears in the app until the scanner ships.
//
// When the scanner goes live:
//   • kScannerLive = true exposes the Deal Check button + this screen
//   • the Scan button below is pre-wired — point _onScan() at your scan flow
//
// Self-contained, no new packages (animations are pure Flutter).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/collection.dart';
import '../services/api.dart';
import '../services/verified.dart'; // kScannerLive
import '../theme/app_theme.dart';

// Deal tiers by percent off retail.
enum DealTier { none, ok, decent, great }

DealTier _tierFor(double pctOff) {
  if (pctOff < 0.5)  return DealTier.none;   // at/above retail (rounding slack)
  if (pctOff < 15)   return DealTier.ok;
  if (pctOff < 30)   return DealTier.decent;
  return DealTier.great;
}

class DealCheckScreen extends StatefulWidget {
  const DealCheckScreen({super.key});
  @override State<DealCheckScreen> createState() => _State();
}

class _State extends State<DealCheckScreen> with TickerProviderStateMixin {
  final _numCtrl   = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();

  bool _looking = false;
  bool _found   = false;
  double? _retail;

  // Result state
  bool _showResult = false;
  double _pctOff = 0;
  double _saved  = 0;
  DealTier _tier = DealTier.none;

  late final AnimationController _celebrate;

  @override
  void initState() {
    super.initState();
    _numCtrl.addListener(_onNumChange);
    _celebrate = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _numCtrl.removeListener(_onNumChange);
    _celebrate.dispose();
    for (final c in [_numCtrl, _nameCtrl, _priceCtrl]) c.dispose();
    super.dispose();
  }

  void _onNumChange() {
    final v = _numCtrl.text.trim();
    if (v.length >= 4) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && _numCtrl.text.trim() == v) _lookup(v);
      });
    }
  }

  Future<void> _lookup(String num) async {
    if (_looking) return;
    setState(() => _looking = true);
    Map<String, dynamic>? d;
    try {
      d = await context.read<CollectionProvider>().lookupSet(num);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _looking = false;
      if (d != null) {
        _found = true;
        final name = d['name'] as String? ?? '';
        if (name.isNotEmpty && _nameCtrl.text.trim().isEmpty) {
          _nameCtrl.text = name;
        }
      }
    });
    if (d != null) _fetchRetail(d['set_num'] as String? ?? num);
  }

  Future<void> _fetchRetail(String num) async {
    try {
      final price = await Api.instance.fetchRetail(num);
      if (mounted && price != null) setState(() => _retail = price);
    } catch (_) {}
  }

  void _onScan() {
    // PRE-WIRED for when the scanner goes live. Point this at your scan flow
    // (push the scanner, get a set number / barcode back, then call _lookup).
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Scanning coming soon — enter the set number for now'),
    ));
  }

  void _check() {
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '').trim());
    final retail = _retail;
    if (price == null || retail == null || retail <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a set number and the in-store price first'),
      ));
      return;
    }
    final pct   = (retail - price) / retail * 100;
    final saved = retail - price;
    setState(() {
      _pctOff = pct;
      _saved  = saved;
      _tier   = _tierFor(pct);
      _showResult = true;
    });
    _celebrate.forward(from: 0);
  }

  void _reset() {
    setState(() {
      _showResult = false;
      _priceCtrl.clear();
    });
  }

  // ── Tier presentation ───────────────────────────────────────────────────
  Color _tierColor(DealTier t) => switch (t) {
    DealTier.none   => BT.txMuted,
    DealTier.ok     => const Color(0xFF8AB4F8),
    DealTier.decent => BT.green,
    DealTier.great  => BT.gold,
  };
  String _tierLabel(DealTier t) => switch (t) {
    DealTier.none   => 'Full price',
    DealTier.ok     => 'OK deal',
    DealTier.decent => 'Decent deal',
    DealTier.great  => 'Great deal!',
  };
  String _tierEmoji(DealTier t) => switch (t) {
    DealTier.none   => '🟰',
    DealTier.ok     => '👍',
    DealTier.decent => '🎉',
    DealTier.great  => '🤑',
  };
  String _tierBlurb(DealTier t) => switch (t) {
    DealTier.none   => 'This is at or above retail — not really a discount.',
    DealTier.ok     => 'A small saving. Fine if you want it, but nothing special.',
    DealTier.decent => 'A solid discount — worth grabbing.',
    DealTier.great  => 'Excellent price. If you want it, buy it.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BT.cream,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: const BoxDecoration(
              color: BT.cream,
              border: Border(bottom: BorderSide(color: BT.ink, width: BT.bw)),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: BT.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: BT.shadowSm,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: BT.ink, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Text('Deal Check', style: BT.display(size: 26)),
            ]),
          ),

          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: _showResult ? _resultView() : _inputView(),
          )),
        ]),
      ),
    );
  }

  // ── Input view ────────────────────────────────────────────────────────────
  Widget _inputView() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Is it a good deal?', style: BT.display(size: 22)),
      const SizedBox(height: 4),
      Text('Scan or enter a set, type the in-store price, and see how much '
          'off retail it is.', style: BT.mono(size: 11, color: BT.tx2)),
      const SizedBox(height: 18),

      // Set number + scan
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _field('Set number', _numCtrl,
          hint: 'e.g. 75192',
          keyboard: TextInputType.number,
          digitsOnly: true,
          suffix: _looking
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(BT.green)))
              : _found
                  ? const Icon(Icons.check_circle, color: BT.green, size: 18)
                  : null,
        )),
        const SizedBox(width: 10),
        // Scan button — pre-wired, shown only when the scanner is live.
        if (kScannerLive)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              onTap: _onScan,
              child: Container(
                width: 52, height: 50,
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BT.ink, width: BT.bw),
                  boxShadow: BT.shadowSm,
                ),
                child: const Icon(Icons.qr_code_scanner, color: BT.ink, size: 22),
              ),
            ),
          ),
      ]),

      _field('Name', _nameCtrl, hint: 'Auto-fills from set number'),

      // Retail readout
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: BT.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BT.ink, width: BT.bw),
        ),
        child: Row(children: [
          Text('Retail / MSRP', style: BT.mono(size: 11, color: BT.tx3)),
          const Spacer(),
          Text(_retail != null ? '\$${_retail!.toStringAsFixed(2)}' : '—',
              style: BT.body(size: 15)),
        ]),
      ),

      _field('In-store price', _priceCtrl,
          hint: '0.00', prefix: '\$',
          keyboard: const TextInputType.numberWithOptions(decimal: true)),

      const SizedBox(height: 8),
      GestureDetector(
        onTap: _check,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: BT.ink,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BT.ink, width: BT.bw),
            boxShadow: BT.shadow,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.local_offer_outlined, color: BT.yellow, size: 20),
            const SizedBox(width: 8),
            Text('Check the deal', style: BT.body(size: 16, color: BT.yellow)),
          ]),
        ),
      ),
    ]);
  }

  // ── Result view (animated) ──────────────────────────────────────────────
  Widget _resultView() {
    final color = _tierColor(_tier);
    return AnimatedBuilder(
      animation: _celebrate,
      builder: (_, __) {
        final t = Curves.easeOutBack.transform(
            _celebrate.value.clamp(0.0, 1.0));
        final pop = 0.6 + 0.4 * t;
        return Column(children: [
          const SizedBox(height: 10),

          // Animated brick burst (only for actual deals)
          SizedBox(
            height: 120,
            child: _tier == DealTier.none
                ? Center(child: Text(_tierEmoji(_tier),
                    style: const TextStyle(fontSize: 56)))
                : CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _BrickBurstPainter(
                      progress: _celebrate.value,
                      color: color,
                      intensity: _tier == DealTier.great ? 1.0
                          : _tier == DealTier.decent ? 0.65 : 0.35,
                    ),
                    child: Center(child: Transform.scale(
                      scale: pop,
                      child: Text(_tierEmoji(_tier),
                          style: const TextStyle(fontSize: 56)),
                    )),
                  ),
          ),

          const SizedBox(height: 8),
          Transform.scale(
            scale: pop,
            child: Text(_tierLabel(_tier),
                style: BT.display(size: 30, color: color)),
          ),
          const SizedBox(height: 6),

          // The number
          Text(
            _tier == DealTier.none
                ? 'No discount'
                : '${_pctOff.toStringAsFixed(0)}% off',
            style: BT.display(size: 44),
          ),
          if (_tier != DealTier.none)
            Text('You save \$${_saved.toStringAsFixed(2)}',
                style: BT.body(size: 15, color: BT.green)),

          const SizedBox(height: 14),
          Opacity(
            opacity: t,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BT.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadowSm,
              ),
              child: Column(children: [
                if (_nameCtrl.text.trim().isNotEmpty)
                  Text(_nameCtrl.text.trim(),
                      style: BT.body(size: 14), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Retail \$${(_retail ?? 0).toStringAsFixed(2)}',
                      style: BT.mono(size: 11, color: BT.tx3)),
                  const SizedBox(width: 10),
                  Text('Price \$${_priceCtrl.text.trim()}',
                      style: BT.mono(size: 11, color: BT.tx3)),
                ]),
                const SizedBox(height: 8),
                Text(_tierBlurb(_tier),
                    style: BT.mono(size: 11, color: BT.tx2),
                    textAlign: TextAlign.center),
              ]),
            ),
          ),

          const SizedBox(height: 18),
          GestureDetector(
            onTap: _reset,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: BT.ink,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadow,
              ),
              child: Center(child: Text('Check another',
                  style: BT.body(size: 15, color: BT.yellow))),
            ),
          ),
        ]);
      },
    );
  }

  // Shared field (mirrors AddSet / wishlist style)
  Widget _field(String label, TextEditingController ctrl, {
    String? hint, String? prefix, Widget? suffix,
    TextInputType? keyboard, bool digitsOnly = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: BT.mono(size: 9, color: BT.tx3)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BT.ink, width: BT.bw),
              boxShadow: BT.shadowSm,
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              inputFormatters: digitsOnly
                  ? [FilteringTextInputFormatter.digitsOnly] : null,
              style: BT.mono(size: 14, color: BT.tx),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: BT.mono(size: 12, color: BT.txMuted),
                prefixText: prefix,
                prefixStyle: BT.mono(size: 14, color: BT.txMuted),
                suffixIcon: suffix != null
                    ? Padding(padding: const EdgeInsets.only(right: 10),
                        child: suffix)
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                fillColor: BT.white,
                filled: true,
              ),
            ),
          ),
        ]),
      );
}

// ── Brick burst animation painter ─────────────────────────────────────────────
class _BrickBurstPainter extends CustomPainter {
  final double progress;   // 0..1
  final Color  color;
  final double intensity;  // 0..1 — more bricks / bigger spread for better deals
  _BrickBurstPainter({
    required this.progress,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final p  = Paint()..style = PaintingStyle.fill;

    final count = (8 + intensity * 16).round();
    final maxR  = (40 + intensity * 90);
    final ease  = Curves.easeOut.transform(progress.clamp(0.0, 1.0));

    for (int i = 0; i < count; i++) {
      final ang = (i / count) * 2 * math.pi + i * 0.6;
      final dist = maxR * ease * (0.5 + (i % 5) / 8);
      final x = cx + dist * 0.95 * math.cos(ang);
      final y = cy + dist * 0.7  * math.sin(ang) - ease * 8;

      // fade out toward the end
      final fade = (1.0 - (progress - 0.5).clamp(0.0, 0.5) * 2).clamp(0.0, 1.0);
      final pal = [color, BT.yellow, BT.ink];
      p.color = pal[i % pal.length].withOpacity(0.85 * fade);

      final s = 5.0 + (i % 3) * 2.0;
      // little rotating brick (rounded rect)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang + ease * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s * 1.6, height: s),
          const Radius.circular(1.5),
        ), p);
      // stud
      p.color = p.color.withOpacity(0.5 * fade);
      canvas.drawCircle(Offset(0, -s * 0.4), s * 0.18, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BrickBurstPainter old) =>
      old.progress != progress || old.color != color ||
      old.intensity != intensity;
}
