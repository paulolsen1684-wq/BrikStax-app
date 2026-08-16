// lib/screens/set_lookup_screen.dart
//
// Set Lookup — type any set number (owned or not) and see a full breakdown:
// pieces, retail, cost/piece, retirement status, and eBay sealed/open
// averages. Distinct from Deal Check (which compares an in-store sticker
// price against retail) and from SetDetailScreen (which only renders sets
// already saved to the collection) — this is a pure "what is this set worth
// and where does it stand" reference tool that works for a set you don't
// (yet) own, which is also why it doubles as the concrete UI for the
// "discovery" reward idea: looking up an unowned set is the exact action
// that idea was designed around, achievement hook not wired yet.
//
// Self-contained, no new packages (mirrors deal_check_screen.dart's style).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/collection.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import 'add_set.dart';
import 'set_detail.dart';

class SetLookupScreen extends StatefulWidget {
  const SetLookupScreen({super.key});
  @override State<SetLookupScreen> createState() => _State();
}

class _State extends State<SetLookupScreen> {
  final _numCtrl = TextEditingController();

  bool _looking = false;
  String? _error;
  Map<String, dynamic>? _rb;                 // Rebrickable: name/pieces/year/theme/image
  ({double? retail, DateTime? exitDate})? _bs; // BrickSet: retail + retirement

  // eBay loads separately and slower than the above two, so the rest of the
  // breakdown can render immediately instead of waiting on it -- matches
  // the app's general "never block on eBay" handling elsewhere (CollectionProvider
  // .refreshEbay tolerates individual failures the same way).
  bool _ebayLoading = false;
  double? _ebaySealed;
  double? _ebayOpen;

  String _lookedUpNum = ''; // the exact string we last successfully resolved

  @override
  void initState() {
    super.initState();
    _numCtrl.addListener(_onNumChange);
  }

  @override
  void dispose() {
    _numCtrl.removeListener(_onNumChange);
    _numCtrl.dispose();
    super.dispose();
  }

  void _onNumChange() {
    final v = _numCtrl.text.trim();
    if (v.length < 4) {
      if (_rb != null || _error != null) {
        setState(() { _rb = null; _bs = null; _error = null; _ebaySealed = null; _ebayOpen = null; });
      }
      return;
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _numCtrl.text.trim() == v) _lookup(v);
    });
  }

  Future<void> _lookup(String num) async {
    if (_looking || num == _lookedUpNum) return;
    setState(() {
      _looking = true;
      _error = null;
      _rb = null;
      _bs = null;
      _ebaySealed = null;
      _ebayOpen = null;
    });

    final rb = await Api.instance.fetchSet(num);
    if (!mounted) return;
    if (rb == null) {
      setState(() { _looking = false; _error = 'No set found for "$num"'; });
      return;
    }

    _lookedUpNum = num;
    setState(() { _rb = rb; _looking = false; });

    // Best-effort, independent of the Rebrickable result above.
    final cleanNum = (rb['set_num'] as String? ?? num).replaceAll(RegExp(r'-\d+$'), '');
    Api.instance.fetchSetDetails(cleanNum).then((bs) {
      if (mounted && _lookedUpNum == num) setState(() => _bs = bs);
    });

    _fetchEbay(cleanNum, rb['name'] as String? ?? '', num);
  }

  // `forNum` is the lookup this fetch was started for -- compared against
  // _lookedUpNum before either setState below applies. Looking up set A,
  // then quickly looking up set B before A's (slower, two-sequential-call)
  // eBay fetch finishes, used to let A's stale prices land on top of B's
  // display once A finally resolved: the old guard only checked
  // `_lookedUpNum.isEmpty`, which is false the instant ANY lookup has ever
  // completed, not just this one.
  Future<void> _fetchEbay(String setNum, String name, String forNum) async {
    setState(() => _ebayLoading = true);
    try {
      final sealed = await Api.instance.fetchEbay(setNum, name, sealed: true);
      if (!mounted || _lookedUpNum != forNum) return;
      if (sealed?['source'] != 'cache') {
        await Future.delayed(const Duration(milliseconds: 1200));
      }
      final open = await Api.instance.fetchEbay(setNum, name, sealed: false);
      if (!mounted || _lookedUpNum != forNum) return;
      setState(() {
        _ebaySealed = (sealed?['avg'] as num?)?.toDouble();
        _ebayOpen   = (open?['avg']   as num?)?.toDouble();
        _ebayLoading = false;
      });
    } catch (_) {
      if (mounted && _lookedUpNum == forNum) setState(() => _ebayLoading = false);
    }
  }

  String _monthYear(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Scaffold(
      backgroundColor: bt.surface,
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: bt.surface,
              border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
            ),
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
              Text('Set Lookup', style: BT.display(size: 26, color: bt.tx)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Look up any set', style: BT.display(size: 20, color: bt.tx)),
                const SizedBox(height: 4),
                Text(
                  "Pieces, price, retirement status, and eBay value — whether you own it or not.",
                  style: BT.mono(size: 11, color: bt.tx2),
                ),
                const SizedBox(height: 18),
                _numField(bt),
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: BT.body(size: 13, color: BT.red)),
                ),
                if (_rb != null) ...[
                  const SizedBox(height: 18),
                  _breakdown(bt),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _numField(BrikStaxColors bt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Set number', style: BT.mono(size: 9, color: bt.tx3)),
      const SizedBox(height: 5),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
        ),
        child: TextField(
          controller: _numCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: BT.mono(size: 15, color: bt.tx),
          decoration: InputDecoration(
            hintText: 'e.g. 75192',
            hintStyle: BT.mono(size: 13, color: bt.txMuted),
            suffixIcon: _looking
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(BT.green))),
                  )
                : _rb != null
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.check_circle, color: BT.green, size: 20))
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            fillColor: bt.cardBg,
            filled: true,
          ),
        ),
      ),
    ],
  );

  Widget _breakdown(BrikStaxColors bt) {
    final rb = _rb!;
    final name  = rb['name'] as String? ?? '';
    final num   = (rb['set_num'] as String? ?? '').replaceAll(RegExp(r'-\d+$'), '');
    final pieces = rb['num_parts'] as int?;
    final year   = rb['year'] as int?;
    final theme  = rb['theme_name'] as String?;
    final image  = rb['set_img_url'] as String?;
    final retail = _bs?.retail;
    final costPerPiece = (retail != null && pieces != null && pieces > 0)
        ? retail / pieces : null;

    final col = context.watch<CollectionProvider>();
    final owned = col.sets.where((s) => s.num == num).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
        boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: bt.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            clipBehavior: Clip.antiAlias,
            child: image != null
                ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: bt.txMuted))
                : Icon(Icons.inventory_2_outlined, color: bt.txMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isNotEmpty ? name : 'Set $num',
                style: BT.body(size: 15, weight: FontWeight.w800, color: bt.tx),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              [num, if (year != null) '$year', if (theme != null) theme].join(' · '),
              style: BT.mono(size: 10, color: bt.tx3),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
        ]),

        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _stat(bt, 'Pieces', pieces != null ? '$pieces' : '—'),
          _stat(bt, 'Retail', retail != null ? '\$${retail.toStringAsFixed(2)}' : '—'),
          _stat(bt, 'Cost/piece', costPerPiece != null ? '${(costPerPiece * 100).toStringAsFixed(1)}¢' : '—'),
          _stat(bt, 'eBay sealed',
              _ebayLoading && _ebaySealed == null ? '…' :
              _ebaySealed != null ? '\$${_ebaySealed!.toStringAsFixed(0)}' : '—',
              color: BT.green),
          _stat(bt, 'eBay open',
              _ebayLoading && _ebayOpen == null ? '…' :
              _ebayOpen != null ? '\$${_ebayOpen!.toStringAsFixed(0)}' : '—',
              color: BT.green),
        ]),

        const SizedBox(height: 14),
        _retirementRow(bt),

        const SizedBox(height: 14),
        if (owned.isNotEmpty)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SetDetailScreen(setId: owned.first.id))),
            child: _actionButton(bt, '✓ Already in your collection — view it',
                bg: BT.green, fg: BT.white),
          )
        else
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddSetScreen(initialNum: num, prefill: rb))),
            child: _actionButton(bt, '+ Add to collection', bg: bt.tx, fg: bt.surface),
          ),
      ]),
    );
  }

  Widget _retirementRow(BrikStaxColors bt) {
    final exitDate = _bs?.exitDate;
    String label;
    Color color;
    if (_bs == null) {
      label = 'Checking retirement status…';
      color = bt.txMuted;
    } else if (exitDate == null) {
      label = 'Retirement status unknown';
      color = bt.txMuted;
    } else if (DateTime.now().isBefore(exitDate)) {
      label = 'Retiring ~${_monthYear(exitDate)}';
      color = BT.gold;
    } else {
      final now = DateTime.now();
      final months = (now.year - exitDate.year) * 12 + (now.month - exitDate.month);
      final climbing = months >= 18 && months <= 24;
      label = 'Retired ${_monthYear(exitDate)}'
          '${climbing ? ' · in price-climb window' : ''}';
      color = climbing ? BT.green : bt.tx2;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bt.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
      ),
      child: Row(children: [
        Icon(Icons.hourglass_bottom, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: BT.body(size: 12, color: color, weight: FontWeight.w600))),
      ]),
    );
  }

  Widget _stat(BrikStaxColors bt, String label, String value, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: bt.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: BT.mono(size: 9, color: bt.tx3)),
      const SizedBox(height: 2),
      Text(value, style: BT.body(size: 14, weight: FontWeight.w700, color: color ?? bt.tx)),
    ]),
  );

  Widget _actionButton(BrikStaxColors bt, String label, {required Color bg, required Color fg}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
    ),
    child: Center(child: Text(label, style: BT.body(size: 13, weight: FontWeight.w700, color: fg))),
  );
}
