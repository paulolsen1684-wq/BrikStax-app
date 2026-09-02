// lib/screens/minifig_lookup_screen.dart
//
// Minifig Lookup — type any Rebrickable fig number (e.g. "fig-000001") and see its name,
// image, and part count via Rebrickable's free minifig catalog, then either
// jump to it if it's already in the collection or add it directly. Mirrors
// set_lookup_screen.dart's debounced-search shape, but simpler: no
// intermediate AddSetScreen-style prefill screen, since a minifig has no
// purchase-price complexity at add time -- condition/qty are editable from
// MinifigDetailScreen after adding.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../models/minifig.dart';
import '../services/api.dart';
import '../services/minifig_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import 'minifig_detail_screen.dart';

class MinifigLookupScreen extends StatefulWidget {
  const MinifigLookupScreen({super.key});
  @override State<MinifigLookupScreen> createState() => _State();
}

class _State extends State<MinifigLookupScreen> {
  final _figCtrl = TextEditingController();
  static const _uuid = Uuid();

  bool _looking = false;
  String? _error;
  Map<String, dynamic>? _rb; // Rebrickable: name/img/num_parts
  String _lookedUpFig = '';

  @override
  void initState() {
    super.initState();
    _figCtrl.addListener(_onFigChange);
  }

  @override
  void dispose() {
    _figCtrl.removeListener(_onFigChange);
    _figCtrl.dispose();
    super.dispose();
  }

  void _onFigChange() {
    final v = _figCtrl.text.trim();
    if (v.length < 4) {
      if (_rb != null || _error != null) {
        setState(() { _rb = null; _error = null; });
      }
      return;
    }
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted && _figCtrl.text.trim() == v) _lookup(v);
    });
  }

  Future<void> _lookup(String fig) async {
    if (_looking || fig == _lookedUpFig) return;
    setState(() { _looking = true; _error = null; _rb = null; });

    final rb = await Api.instance.fetchMinifig(fig);
    if (!mounted) return;
    if (rb == null) {
      setState(() { _looking = false; _error = 'No minifig found for "$fig"'; });
      return;
    }
    _lookedUpFig = fig;
    setState(() { _rb = rb; _looking = false; });
  }

  Future<void> _add(String fig, Map<String, dynamic> rb) async {
    final item = Minifig(
      id: _uuid.v4(),
      figNum: fig,
      name: rb['name'] as String? ?? '',
      imageUrl: rb['set_img_url'] as String?,
      numParts: rb['num_parts'] as int?,
      addedAt: DateTime.now(),
    );
    await MinifigService.instance.add(item);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => MinifigDetailScreen(figNum: fig)));
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
              Text('Minifig Lookup', style: BT.display(size: 24, color: bt.tx)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Look up any minifig', style: BT.display(size: 20, color: bt.tx)),
                const SizedBox(height: 4),
                Text(
                  'Enter its Rebrickable fig number, e.g. "fig-000001".',
                  style: BT.mono(size: 11, color: bt.tx2),
                ),
                const SizedBox(height: 18),
                _figField(bt),
                if (_error != null) Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: BT.body(size: 13, color: BT.red)),
                ),
                if (_rb != null) ...[
                  const SizedBox(height: 18),
                  _result(bt),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _figField(BrikStaxColors bt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Fig number', style: BT.mono(size: 9, color: bt.tx3)),
      const SizedBox(height: 5),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
        ),
        child: TextField(
          controller: _figCtrl,
          textCapitalization: TextCapitalization.none,
          style: BT.mono(size: 15, color: bt.tx),
          decoration: InputDecoration(
            hintText: 'e.g. fig-000001',
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

  Widget _result(BrikStaxColors bt) {
    final rb = _rb!;
    final fig = _lookedUpFig;
    final name = rb['name'] as String? ?? '';
    final parts = rb['num_parts'] as int?;
    final image = rb['set_img_url'] as String?;

    final svc = context.watch<MinifigService>();
    final owned = svc.contains(fig);

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
                    errorWidget: (_, __, ___) => Icon(Icons.emoji_people, color: bt.txMuted))
                : Icon(Icons.emoji_people, color: bt.txMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isNotEmpty ? name : fig,
                style: BT.body(size: 15, weight: FontWeight.w800, color: bt.tx),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              [fig, if (parts != null) '$parts parts'].join(' · '),
              style: BT.mono(size: 10, color: bt.tx3),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        if (owned)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MinifigDetailScreen(figNum: fig))),
            child: _actionButton(bt, '✓ Already in your minifigs — view it',
                bg: BT.green, fg: BT.white),
          )
        else
          GestureDetector(
            onTap: () => _add(fig, rb),
            child: _actionButton(bt, '+ Add to my minifigs', bg: bt.tx, fg: bt.surface),
          ),
      ]),
    );
  }

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
