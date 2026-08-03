// lib/widgets/sheets.dart — BrikStax bottom sheets
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/lego_set.dart';
import '../theme/app_theme.dart';
import 'atoms.dart';

// ── Open Extras Sheet ──────────────────────────────────────────────────────────
class OpenExtrasSheet extends StatefulWidget {
  final OpenExtras initial;
  final void Function(OpenExtras) onSave;
  const OpenExtrasSheet({super.key, required this.initial, required this.onSave});

  static Future<OpenExtras?> show(BuildContext ctx, OpenExtras current) async {
    OpenExtras? result;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: BT.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: BT.ink, width: BT.bw),
      ),
      builder: (_) => OpenExtrasSheet(
        initial: current,
        onSave: (v) { result = v; Navigator.pop(ctx); },
      ),
    );
    return result;
  }

  @override
  State<OpenExtrasSheet> createState() => _OpenExtrasSheetState();
}

class _OpenExtrasSheetState extends State<OpenExtrasSheet> {
  late bool _box, _manual;

  @override
  void initState() {
    super.initState();
    _box    = widget.initial.hasBox;
    _manual = widget.initial.hasManual;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        Text('Open set accessories', style: BT.display(size: 24))
            .animate().fadeIn(duration: 250.ms).slideY(begin: -.1, end: 0),
        const SizedBox(height: 4),
        Text('Track what came with this open set',
            style: BT.mono(size: 10)).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 18),
        _Toggle(
          icon: Icons.inventory_2_outlined,
          label: 'Original box',
          sub: 'Still has original packaging',
          value: _box,
          onChange: (v) => setState(() => _box = v),
        ).animate().fadeIn(delay: 80.ms, duration: 240.ms),
        const SizedBox(height: 10),
        _Toggle(
          icon: Icons.menu_book_outlined,
          label: 'Instruction manual',
          sub: 'Still has building instructions',
          value: _manual,
          onChange: (v) => setState(() => _manual = v),
        ).animate().fadeIn(delay: 130.ms, duration: 240.ms),
        const SizedBox(height: 18),
        // Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BT.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 15, color: BT.tx3),
            const SizedBox(width: 10),
            Text(_summary(), style: BT.mono(size: 11, color: BT.tx2)),
          ]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              widget.onSave(OpenExtras(hasBox: _box, hasManual: _manual)),
          child: const Text('Save'),
        ),
      ]),
    ),
  );

  String _summary() {
    if (_box && _manual) return 'Complete — original box + manual';
    if (_box)            return 'Has original box, no manual';
    if (_manual)         return 'Has manual, no original box';
    return 'No box or manual';
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   sub;
  final bool     value;
  final void Function(bool) onChange;
  const _Toggle({required this.icon, required this.label, required this.sub, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChange(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: value ? BT.yellowBg : BT.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? BT.yellow3 : BT.ink, width: BT.bw),
        boxShadow: value ? [] : BT.shadowSm,
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: value ? BT.yellow : BT.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: Icon(icon, size: 18, color: BT.ink),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: BT.body(size: 14)),
          Text(sub, style: BT.mono(size: 10)),
        ])),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: value ? BT.ink : BT.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: BT.ink, width: BT.bw),
          ),
          child: value
              ? const Icon(Icons.check, color: BT.yellow, size: 14)
              : null,
        ),
      ]),
    ),
  );
}

// ── Purchase Source Sheet ──────────────────────────────────────────────────────
class PurchaseSourceSheet extends StatelessWidget {
  final PurchaseSource current;
  final void Function(PurchaseSource) onSelect;
  const PurchaseSourceSheet({super.key, required this.current, required this.onSelect});

  static Future<PurchaseSource?> show(BuildContext ctx, PurchaseSource current) async {
    PurchaseSource? result;
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: BT.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: BT.ink, width: BT.bw),
      ),
      builder: (_) => PurchaseSourceSheet(
        current: current,
        onSelect: (v) { result = v; Navigator.pop(ctx); },
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SheetHandle(),
        const SizedBox(height: 14),
        Text('Where did you buy it?', style: BT.display(size: 24)),
        const SizedBox(height: 4),
        Text('LEGO Store & LEGO.com earn 5% back in Insider points',
            style: BT.mono(size: 10)),
        const SizedBox(height: 16),
        ...PurchaseSource.values.asMap().entries.map((e) {
          final src = e.value;
          final sel  = src == current;
          final lego = src.earnsInsiderPoints;
          return GestureDetector(
            onTap: () => onSelect(src),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color:        sel ? (lego ? BT.yellowBg : BT.cream2) : BT.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: sel ? (lego ? BT.yellow3 : BT.ink) : BT.cream3,
                  width: sel ? BT.bw : 1.5,
                ),
                boxShadow: sel ? [] : BT.shadowSm,
              ),
              child: Row(children: [
                Text(src.emoji, style: const TextStyle(fontSize: 19)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(src.label, style: BT.body(size: 14)),
                  if (lego) Text('Earns 5% Insider points',
                      style: BT.mono(size: 9, color: BT.gold)),
                ])),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: sel ? BT.ink : BT.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BT.ink, width: BT.bw),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: BT.yellow, size: 13)
                      : null,
                ),
              ]),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 25 * e.key), duration: 200.ms),
          );
        }),
      ]),
    ),
  );
}
