// lib/screens/minifig_detail_screen.dart
//
// One minifig's detail: image/name/parts, owned/wanted toggle, qty,
// condition, source sets (if known), and the value section -- cached value +
// staleness + a "Check current value" button. The button is the ONLY place
// in the whole feature that can spend the shared BrickEconomy budget, and
// only fires on an explicit tap here, never automatically on this screen's
// own build -- see MinifigService.refreshValue's doc comment.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/minifig.dart';
import '../services/api.dart';
import '../services/feature_flag_service.dart';
import '../services/minifig_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

class MinifigDetailScreen extends StatefulWidget {
  final String figNum;
  const MinifigDetailScreen({super.key, required this.figNum});
  @override State<MinifigDetailScreen> createState() => _State();
}

class _State extends State<MinifigDetailScreen> {
  bool _checkingValue = false;
  String? _valueError;

  Future<void> _checkValue(Minifig item) async {
    setState(() { _checkingValue = true; _valueError = null; });
    try {
      await MinifigService.instance.refreshValue(item);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _valueError = switch (e.code) {
        'rate_limited' || 'brickeconomy_daily_cap_reached' || 'brickeconomy_busy_try_again' =>
          'Value lookups are limited — try again tomorrow.',
        _ => "Couldn't check the value right now.",
      });
    } catch (_) {
      if (mounted) setState(() => _valueError = "Couldn't check the value right now.");
    } finally {
      if (mounted) setState(() => _checkingValue = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final svc = context.watch<MinifigService>();
    final item = svc.items.where((m) => m.figNum == widget.figNum).firstOrNull;

    if (item == null) {
      return Scaffold(
        backgroundColor: bt.surface,
        appBar: AppBar(backgroundColor: bt.surface, elevation: 0),
        body: Center(child: Text('Minifig not found', style: BT.body(color: bt.tx2))),
      );
    }

    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        backgroundColor: bt.surface,
        elevation: 0,
        title: Text(item.name.isNotEmpty ? item.name : item.figNum,
            style: BT.display(size: 18, color: bt.tx)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: bt.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.imageUrl != null
                    ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.emoji_people, color: bt.txMuted))
                    : Icon(Icons.emoji_people, color: bt.txMuted, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name.isNotEmpty ? item.name : item.figNum,
                    style: BT.body(size: 16, weight: FontWeight.w800, color: bt.tx)),
                const SizedBox(height: 3),
                Text(
                  [item.figNum, if (item.numParts != null) '${item.numParts} parts'].join(' · '),
                  style: BT.mono(size: 11, color: bt.tx3),
                ),
              ])),
            ]),

            const SizedBox(height: 18),
            _statusRow(bt, item),

            const SizedBox(height: 18),
            _valueSection(bt, item),

            if (item.fromSetNums.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Comes from', style: BT.mono(size: 10, color: bt.tx3)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in item.fromSetNums)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                    ),
                    child: Text(s, style: BT.mono(size: 11, color: bt.tx2)),
                  ),
              ]),
            ],

            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await MinifigService.instance.remove(item.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: bt.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: Center(child: Text('Remove from my minifigs',
                    style: BT.body(size: 13, weight: FontWeight.w700, color: BT.red))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statusRow(BrikStaxColors bt, Minifig item) => Row(children: [
    Expanded(child: _pickerTile(bt, 'Status', item.status == 'owned' ? 'Owned' : 'Wanted',
        onTap: () => MinifigService.instance.update(item.copyWith(
            status: item.status == 'owned' ? 'wanted' : 'owned')))),
    const SizedBox(width: 10),
    Expanded(child: _pickerTile(bt, 'Qty', '${item.qty}',
        onTap: () => MinifigService.instance.update(
            item.copyWith(qty: item.qty >= 20 ? 1 : item.qty + 1)))),
    const SizedBox(width: 10),
    Expanded(child: _pickerTile(bt, 'Condition', _conditionLabel(item.condition),
        onTap: () => MinifigService.instance.update(
            item.copyWith(condition: _nextCondition(item.condition))))),
  ]);

  String _conditionLabel(String c) => switch (c) {
    'good' => 'Good',
    'incomplete' => 'Incomplete',
    _ => 'Mint',
  };
  String _nextCondition(String c) => switch (c) {
    'mint' => 'good',
    'good' => 'incomplete',
    _ => 'mint',
  };

  Widget _pickerTile(BrikStaxColors bt, String label, String value, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: bt.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: BT.mono(size: 9, color: bt.tx3)),
            const SizedBox(height: 3),
            Text(value, style: BT.body(size: 13, weight: FontWeight.w700, color: bt.tx)),
          ]),
        ),
      );

  Widget _valueSection(BrikStaxColors bt, Minifig item) {
    // FeatureFlagService isn't Provider-registered (same as most other
    // singletons here) -- read .instance directly rather than context.watch,
    // matching how the rest of the app treats it. It's fetched once at
    // launch and doesn't change mid-session, so no listener is needed.
    final gated = !FeatureFlagService.instance.minifigValuesEnabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Market value', style: BT.mono(size: 10, color: bt.tx3)),
        const SizedBox(height: 6),
        if (item.hasValue)
          Text('\$${item.valueUsd!.toStringAsFixed(2)}',
              style: BT.display(size: 22, color: bt.tx))
        else if (item.valueZeroResult)
          Text('No value found', style: BT.body(size: 14, color: bt.tx2))
        else
          Text('Not checked yet', style: BT.body(size: 14, color: bt.txMuted)),
        if (item.valueFetchedAt != null) ...[
          const SizedBox(height: 3),
          Text(
            item.valueIsStale ? 'Checked a while ago' : 'Checked recently',
            style: BT.mono(size: 9, color: bt.tx3),
          ),
        ],
        const SizedBox(height: 10),
        if (gated)
          Text('Value lookups aren\'t enabled yet.',
              style: BT.mono(size: 10, color: bt.txMuted))
        else
          GestureDetector(
            onTap: _checkingValue ? null : () => _checkValue(item),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: bt.tx,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Center(
                child: _checkingValue
                    ? SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(bt.surface)))
                    : Text('Check current value',
                        style: BT.body(size: 13, weight: FontWeight.w700, color: bt.surface)),
              ),
            ),
          ),
        if (_valueError != null) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_valueError!, style: BT.body(size: 12, color: BT.red)),
        ),
      ]),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
