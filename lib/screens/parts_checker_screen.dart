// lib/screens/parts_checker_screen.dart
//
// Native port of cloudflare-site/checker.html's Parts Checker: pull a set's
// full piece list, mark what you actually have, see complete/partial/
// missing at a glance, export what's still missing. Same Worker endpoint
// (GET /parts?set=) and the same core idea, but two real upgrades over the
// website version:
//   - Progress persists to SQLite via PartCheckService, keyed by set
//     number, with no slot limit and no dependency on staying on the same
//     device/browser tab (the website has exactly 3 localStorage slots).
//   - Reachable two ways: freeform (any set number, matches Set Lookup's
//     UX) from the dashboard, or pre-filled and auto-loaded from
//     SetDetailScreen for a set you own and marked "open" -- see
//     `ownedSetName`, which just changes a banner, not the data source
//     (progress is always keyed by set number either way, so freeform and
//     owned-set entry into the same set number share the same progress).
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/checker_part.dart';
import '../providers/collection.dart';
import '../services/api.dart';
import '../services/part_check_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

class PartsCheckerScreen extends StatefulWidget {
  /// Pre-fill and auto-check this set number on open (e.g. launched from
  /// SetDetailScreen). Leave null for the freeform dashboard entry point.
  final String? initialNum;

  /// Set when launched from an owned "open" LegoSet -- purely cosmetic (a
  /// banner naming it), not a different data source; see file doc comment.
  final String? ownedSetName;

  const PartsCheckerScreen({super.key, this.initialNum, this.ownedSetName});

  @override
  State<PartsCheckerScreen> createState() => _PartsCheckerScreenState();
}

class _PartsCheckerScreenState extends State<PartsCheckerScreen> {
  final _numCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  CheckerSetInfo? _setInfo;
  List<CheckerPart> _parts = [];
  final Map<String, int> _have = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialNum != null) {
      _numCtrl.text = widget.initialNum!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final num = _numCtrl.text.trim();
    if (num.isEmpty) {
      setState(() => _error = 'Enter a set number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _setInfo = null;
      _parts = [];
      _have.clear();
    });

    final result = await Api.instance.fetchPartsChecklist(num);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load parts for "$num" -- check the set number.';
      });
      return;
    }

    final saved = await PartCheckService.instance.load(result.set.num);
    if (!mounted) return;
    setState(() {
      _setInfo = result.set;
      _parts = result.parts;
      _have
        ..clear()
        ..addAll(saved);
      _loading = false;
    });
  }

  void _setQty(CheckerPart part, int qty) {
    final clamped = qty < 0 ? 0 : qty;
    setState(() => _have[part.id] = clamped);
    // Fire-and-forget -- a single sqflite write per tap, no need to block
    // the UI on it, same tolerance-for-eventual-consistency the rest of
    // the app already applies to non-critical local writes.
    PartCheckService.instance.setHave(_setInfo!.num, part.id, clamped);
  }

  void _setAllOwned() {
    setState(() {
      for (final p in _parts) {
        _have[p.id] = p.qty;
      }
    });
    for (final p in _parts) {
      PartCheckService.instance.setHave(_setInfo!.num, p.id, p.qty);
    }
  }

  void _clearAll() {
    setState(() {
      for (final p in _parts) {
        _have[p.id] = 0;
      }
    });
    for (final p in _parts) {
      PartCheckService.instance.setHave(_setInfo!.num, p.id, 0);
    }
  }

  Future<void> _exportMissing() async {
    final missing = _parts.where((p) => (_have[p.id] ?? 0) < p.qty).toList();
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have every piece -- nothing to export!')),
      );
      return;
    }
    final rows = <List<String>>[
      ['Part Number', 'Name', 'Color', 'Qty Needed', 'Qty Have', 'Still Need'],
      ...missing.map((p) {
        final have = _have[p.id] ?? 0;
        return [
          p.partNum,
          '"${p.name.replaceAll('"', '""')}"',
          '"${p.color}"',
          '${p.qty}',
          '$have',
          '${p.qty - have}',
        ];
      }),
    ];
    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = XFile.fromData(utf8.encode(csv),
        mimeType: 'text/csv', name: 'missing-parts-${_setInfo!.num}.csv');
    await SharePlus.instance.share(ShareParams(
      files: [file],
      text: 'Missing parts for ${_setInfo!.num} — tracked with BrikStax 🧱',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Scaffold(
      backgroundColor: bt.surface,
      body: SafeArea(
        child: Column(children: [
          _header(bt),
          Expanded(
            child: _setInfo == null ? _preCheckBody(bt) : _checklistBody(bt),
          ),
        ]),
      ),
    );
  }

  Widget _header(BrikStaxColors bt) => Container(
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
          Text('Parts Checker', style: BT.display(size: 26, color: bt.tx)),
        ]),
      );

  Widget _preCheckBody(BrikStaxColors bt) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Check a set for missing pieces', style: BT.display(size: 20, color: bt.tx)),
          const SizedBox(height: 4),
          Text(
            "For a used or incomplete set — mark what you actually have, and see what's still missing.",
            style: BT.mono(size: 11, color: bt.tx2),
          ),
          const SizedBox(height: 18),
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
              onSubmitted: (_) => _check(),
              decoration: InputDecoration(
                hintText: 'e.g. 75192',
                hintStyle: BT.mono(size: 13, color: bt.txMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                fillColor: bt.cardBg,
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loading ? null : _check,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: bt.tx,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Center(
                child: _loading
                    ? SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(bt.surface)))
                    : Text('Check Parts', style: BT.body(size: 14, weight: FontWeight.w700, color: bt.surface)),
              ),
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: BT.body(size: 13, color: BT.red)),
          ),
        ]),
      );

  Widget _checklistBody(BrikStaxColors bt) {
    final s = _setInfo!;
    int complete = 0, partial = 0, missing = 0;
    for (final p in _parts) {
      final have = _have[p.id] ?? 0;
      switch (checkerPartStatus(have, p.qty)) {
        case CheckerPartStatus.complete: complete++; break;
        case CheckerPartStatus.partial: partial++; break;
        case CheckerPartStatus.missing: missing++; break;
      }
    }

    final owned = context.watch<CollectionProvider>().sets
        .where((x) => x.num == s.num && x.status == 'open')
        .toList();

    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.ownedSetName != null)
              _banner(bt, '📋 Checking your copy of ${widget.ownedSetName} — progress saves automatically.', BT.green)
            else if (owned.isNotEmpty)
              _banner(bt, '✓ This matches "${owned.first.name}" in your collection — progress is saved either way.', BT.gold),
            if (widget.ownedSetName != null || owned.isNotEmpty) const SizedBox(height: 10),
            _setBanner(bt, s),
            const SizedBox(height: 12),
            Row(children: [
              _statChip(bt, '$complete', 'Complete', BT.green),
              const SizedBox(width: 8),
              _statChip(bt, '$partial', 'Partial', BT.gold),
              const SizedBox(width: 8),
              _statChip(bt, '$missing', 'Missing', BT.red),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _smallButton(bt, 'Set All Owned', onTap: _setAllOwned)),
              const SizedBox(width: 8),
              Expanded(child: _smallButton(bt, 'Clear All', onTap: _clearAll)),
            ]),
            const SizedBox(height: 8),
            _smallButton(bt, '⬇ Export Missing (CSV)', onTap: _exportMissing, full: true, primary: true),
            const SizedBox(height: 14),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _partCard(bt, _parts[i]),
            childCount: _parts.length,
          ),
        ),
      ),
    ]);
  }

  Widget _banner(BrikStaxColors bt, String text, Color accent) => Container(
        margin: const EdgeInsets.only(bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: BT.bw),
        ),
        child: Text(text, style: BT.body(size: 12, weight: FontWeight.w600, color: accent)),
      );

  Widget _setBanner(BrikStaxColors bt, CheckerSetInfo s) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: bt.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            clipBehavior: Clip.antiAlias,
            child: s.imgUrl != null
                ? CachedNetworkImage(imageUrl: s.imgUrl!, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.inventory_2_outlined, color: bt.txMuted))
                : Icon(Icons.inventory_2_outlined, color: bt.txMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name.isNotEmpty ? s.name : 'Set ${s.num}',
                style: BT.body(size: 14, weight: FontWeight.w800, color: bt.tx),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              [s.num, if (s.year != null) '${s.year}', if (s.numParts != null) '${s.numParts} parts'].join(' · '),
              style: BT.mono(size: 10, color: bt.tx3),
            ),
          ])),
        ]),
      );

  Widget _statChip(BrikStaxColors bt, String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bt.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: Column(children: [
            Text(value, style: BT.display(size: 20, color: color)),
            Text(label, style: BT.mono(size: 8, color: bt.tx3)),
          ]),
        ),
      );

  Widget _smallButton(BrikStaxColors bt, String label,
      {required VoidCallback onTap, bool full = false, bool primary = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: full ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: primary ? BT.yellow3 : bt.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: Center(
            child: Text(label, style: BT.mono(size: 11, weight: FontWeight.w700, color: bt.tx)),
          ),
        ),
      );

  Widget _partCard(BrikStaxColors bt, CheckerPart p) {
    final have = _have[p.id] ?? 0;
    final status = checkerPartStatus(have, p.qty);
    final color = switch (status) {
      CheckerPartStatus.complete => BT.green,
      CheckerPartStatus.partial => BT.gold,
      CheckerPartStatus.missing => BT.red,
    };
    final label = switch (status) {
      CheckerPartStatus.complete => '✓ Complete',
      CheckerPartStatus.partial => '$have/${p.qty} · need ${p.qty - have}',
      CheckerPartStatus.missing => 'Missing all ${p.qty}',
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: BT.bw),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: bt.cardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.imgUrl != null
                ? CachedNetworkImage(imageUrl: p.imgUrl!, fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(Icons.extension_outlined, color: bt.txMuted))
                : Icon(Icons.extension_outlined, color: bt.txMuted),
          ),
        ),
        const SizedBox(height: 6),
        Text(p.name, style: BT.body(size: 10, weight: FontWeight.w700, color: bt.tx),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 3),
        Row(children: [
          if (p.colorHex != null) Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Color(int.parse('FF${p.colorHex!.replaceAll('#', '')}', radix: 16)),
              shape: BoxShape.circle,
              border: Border.all(color: bt.cardBorder, width: 1),
            ),
          ),
          Expanded(child: Text('${p.color} · #${p.partNum}',
              style: BT.mono(size: 8, color: bt.tx3),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _stepBtn(bt, Icons.remove, () => _setQty(p, have - 1)),
          Text('$have', style: BT.mono(size: 13, weight: FontWeight.w700, color: bt.tx)),
          _stepBtn(bt, Icons.add, () => _setQty(p, have + 1)),
        ]),
        const SizedBox(height: 3),
        Text(label, style: BT.mono(size: 8, weight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _stepBtn(BrikStaxColors bt, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: bt.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: bt.cardBorder, width: 1),
          ),
          child: Icon(icon, size: 14, color: bt.tx),
        ),
      );
}
