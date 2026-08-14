// lib/screens/parts_merger_screen.dart
//
// Native port of cloudflare-site/parts-merger.html, deliberately narrower
// in scope than the website (decided 2026-08-13): official LEGO set
// numbers only, up to 20, no MOC CSV upload, and only the BrickLink Wanted
// List XML output (the website's plain PAB/reference CSV isn't built
// here). Same Worker endpoint (POST /parts-merge) and merge semantics --
// same part+color from different sets summed into one row, not duplicated
// -- just a smaller surface than the site's. See merge_part.dart for the
// response parsing and XML-building logic shared with this screen.
//
// Reached from Settings ("Tools" section) rather than the dashboard's
// Discover section, unlike Parts Checker/Set Lookup -- Discover was
// already busy, and this tool isn't tied to a single owned set the way
// Parts Checker's SetDetailScreen entry point is, so it doesn't need
// dashboard-level prominence.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/merge_part.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

const int _kMaxSets = 20;

class PartsMergerScreen extends StatefulWidget {
  const PartsMergerScreen({super.key});

  @override
  State<PartsMergerScreen> createState() => _PartsMergerScreenState();
}

class _PartsMergerScreenState extends State<PartsMergerScreen> {
  final _idsCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  MergeResult? _result;
  String? _xml;
  int _xmlItemCount = 0;
  int _xmlSkipped = 0;

  @override
  void dispose() {
    _idsCtrl.dispose();
    super.dispose();
  }

  List<String> _parseIds(String input) => input
      .split(RegExp(r'[\n,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _merge() async {
    final ids = _parseIds(_idsCtrl.text);
    if (ids.isEmpty) {
      setState(() => _error = 'Enter at least one set number.');
      return;
    }
    if (ids.length > _kMaxSets) {
      setState(() => _error =
          'Too many sets at once (max $_kMaxSets) — you entered ${ids.length}.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    final result = await Api.instance.mergeParts(ids);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _result = result;
        final built = buildBrickLinkXml(result.parts);
        _xml = built.xml;
        _xmlItemCount = built.itemCount;
        _xmlSkipped = built.skipped;
      } else {
        _error = result.error;
      }
    });
  }

  void _reset() {
    setState(() {
      _result = null;
      _error = null;
      _xml = null;
    });
  }

  Future<void> _exportXml() async {
    if (_xml == null || _xmlItemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "None of these parts could be matched to a BrickLink id — nothing to export.")));
      return;
    }
    final file = XFile.fromData(utf8.encode(_xml!),
        mimeType: 'text/xml', name: 'bricklink-wanted-list.xml');
    await SharePlus.instance.share(ShareParams(
      files: [file],
      text:
          'BrickLink Wanted List — merged from ${_result!.setCount} set${_result!.setCount == 1 ? '' : 's'} with BrikStax 🧱',
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
            child: _result == null ? _inputBody(bt) : _resultsBody(bt),
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
          Text('Parts Merger', style: BT.display(size: 26, color: bt.tx)),
        ]),
      );

  Widget _inputBody(BrikStaxColors bt) => SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Combine piece lists from multiple sets',
              style: BT.display(size: 20, color: bt.tx)),
          const SizedBox(height: 4),
          Text(
            'Enter up to $_kMaxSets official LEGO set numbers — same part in the same colour from different sets is summed, not duplicated. Exports as a BrickLink Wanted List you can upload directly.',
            style: BT.mono(size: 11, color: bt.tx2),
          ),
          const SizedBox(height: 18),
          Text('Set numbers', style: BT.mono(size: 9, color: bt.tx3)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
            ),
            child: TextField(
              controller: _idsCtrl,
              minLines: 4,
              maxLines: 8,
              style: BT.mono(size: 14, color: bt.tx),
              onSubmitted: (_) => _merge(),
              decoration: InputDecoration(
                hintText: 'e.g.\n75192\n10307, 21332',
                hintStyle: BT.mono(size: 13, color: bt.txMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                fillColor: bt.cardBg,
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Separate with commas or new lines.',
              style: BT.mono(size: 9, color: bt.txMuted)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loading ? null : _merge,
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
                    : Text('Merge Parts',
                        style: BT.body(size: 14, weight: FontWeight.w700, color: bt.surface)),
              ),
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: BT.body(size: 13, color: BT.red)),
          ),
        ]),
      );

  Widget _resultsBody(BrikStaxColors bt) {
    final r = _result!;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.warnings.isNotEmpty) ...[
              _banner(bt,
                  '⚠️ ${r.warnings.join(' ')}', BT.gold),
              const SizedBox(height: 10),
            ],
            Row(children: [
              _statChip(bt, '${r.setCount}', 'Sets', BT.blue),
              const SizedBox(width: 8),
              _statChip(bt, '${r.parts.length}', 'Parts', bt.tx),
              const SizedBox(width: 8),
              _statChip(bt, '$_xmlItemCount', 'BrickLink-ready', BT.green),
            ]),
            if (_xmlSkipped > 0) ...[
              const SizedBox(height: 10),
              _banner(bt,
                  "$_xmlSkipped part+colour combo${_xmlSkipped == 1 ? '' : 's'} couldn't be matched to a BrickLink id and ${_xmlSkipped == 1 ? "isn't" : "aren't"} in the export.",
                  BT.gold),
            ],
            const SizedBox(height: 12),
            _smallButton(bt, '⬇ Export BrickLink XML', onTap: _exportXml, full: true, primary: true),
            const SizedBox(height: 8),
            _smallButton(bt, 'New Merge', onTap: _reset, full: true),
            const SizedBox(height: 14),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
        sliver: SliverList.separated(
          itemCount: r.parts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _partRow(bt, r.parts[i]),
        ),
      ),
    ]);
  }

  Widget _banner(BrikStaxColors bt, String text, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent, width: BT.bw),
        ),
        child: Text(text, style: BT.body(size: 12, weight: FontWeight.w600, color: accent)),
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
            Text(label, style: BT.mono(size: 8, color: bt.tx3),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _partRow(BrikStaxColors bt, MergedPart p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Row(children: [
          Icon(
            p.hasBrickLinkIds ? Icons.check_circle : Icons.error_outline,
            size: 16,
            color: p.hasBrickLinkIds ? BT.green : BT.gold,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.partNum} · ${p.color}',
                style: BT.body(size: 13, weight: FontWeight.w700, color: bt.tx),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              p.spareQty > 0 ? 'Qty: ${p.qty} (${p.spareQty} spare)' : 'Qty: ${p.qty}',
              style: BT.mono(size: 9, color: bt.tx3),
            ),
          ])),
        ]),
      );
}
