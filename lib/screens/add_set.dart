// lib/screens/add_set.dart — BrikStax Brick UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/lego_set.dart';
import '../providers/collection.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../utils/haptics.dart';
import '../widgets/atoms.dart';
import '../widgets/sheets.dart';
import '../widgets/set_added_celebration.dart';

class AddSetScreen extends StatefulWidget {
  final String?               initialNum;
  final Map<String, dynamic>? prefill;
  /// True when this screen was reached from a real barcode scan
  /// (scanner.dart's Inventory mode) rather than typed in by hand -- gets
  /// passed through to CollectionProvider.addSet's verified param so a
  /// scanned set is trusted regardless of how manual entries are being
  /// treated (see verified.dart's kScannerLive/manualEntryDefaultVerified).
  final bool                  fromScan;
  const AddSetScreen({super.key, this.initialNum, this.prefill, this.fromScan = false});
  @override State<AddSetScreen> createState() => _State();
}

class _State extends State<AddSetScreen> {
  final _form   = GlobalKey<FormState>();
  final _cNum   = TextEditingController();
  final _cName  = TextEditingController();
  final _cRet   = TextEditingController();
  final _cPaid  = TextEditingController();
  final _cQty   = TextEditingController(text: '1');
  final _cNotes = TextEditingController();

  String         _status  = 'sealed';
  PurchaseSource _source  = PurchaseSource.other;
  OpenExtras     _extras  = const OpenExtras();
  bool           _saving  = false;
  bool           _looking = false;
  Map<String, dynamic>? _rb;
  DateTime?      _exitDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialNum != null) {
      _cNum.text = widget.initialNum!;
      // initialNum is set before the listener below is attached, so the
      // normal debounced _onNumChange() never fires for it (e.g. when
      // handed off from the barcode scanner). Trigger the lookup directly
      // once, after the first frame, so name/pieces/year/retail populate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lookup(widget.initialNum!);
      });
    }
    if (widget.prefill != null) _applyRb(widget.prefill!);
    _cNum.addListener(_onNumChange);
  }

  @override
  void dispose() {
    _cNum.removeListener(_onNumChange);
    for (final c in [_cNum, _cName, _cRet, _cPaid, _cQty, _cNotes]) c.dispose();
    super.dispose();
  }

  void _onNumChange() {
    final v = _cNum.text.trim();
    if (v.length >= 4) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted && _cNum.text.trim() == v) _lookup(v);
      });
    }
  }

  Future<void> _lookup(String num) async {
    if (_looking) return;
    setState(() => _looking = true);
    final d = await context.read<CollectionProvider>().lookupSet(num);
    if (mounted) setState(() { _looking = false; if (d != null) _applyRb(d); });
  }

  void _applyRb(Map<String, dynamic> d) {
    _rb = d;
    final setNum = d['set_num'] as String?;
    // Only when the Set number field is still blank -- covers a future
    // AddSetScreen(prefill: ...) call site that doesn't also pass
    // initialNum (today's only call site, set_lookup_screen.dart, always
    // passes both together, so _cNum is already populated by the time
    // this runs from initState -- this guard never fires there). Never
    // overwrites what the user actually typed when this runs from the
    // live _onNumChange -> _lookup path instead.
    if (setNum != null && _cNum.text.trim().isEmpty) _cNum.text = setNum;
    _cName.text = d['name'] as String? ?? '';
    _cRet.text  = '';
    _fetchRetail(setNum ?? _cNum.text.trim());
  }

  Future<void> _fetchRetail(String num) async {
    try {
      final details = await Api.instance.fetchSetDetails(num);
      if (!mounted || details == null) return;
      if (details.retail != null && _cRet.text.isEmpty) {
        setState(() => _cRet.text = details.retail!.toStringAsFixed(2));
      }
      _exitDate = details.exitDate;
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final result = await context.read<CollectionProvider>().addSet(
      num:            _cNum.text.trim(),
      name:           _cName.text.trim(),
      status:         _status,
      qty:            int.tryParse(_cQty.text) ?? 1,
      retail:         double.tryParse(_cRet.text.replaceAll(',', '')),
      paid:           double.tryParse(_cPaid.text.replaceAll(',', '')),
      notes:          _cNotes.text.trim(),
      pieces:         _rb?['num_parts'] as int?,
      year:           _rb?['year'] as int?,
      imageUrl:       _rb?['set_img_url'] as String?,
      theme:          _rb?['theme_name'] as String?,
      subtheme:       _rb?['subtheme_name'] as String?,
      retired:        _rb?['is_obsolete'] as bool? ?? false,
      exitDate:       _exitDate,
      openExtras:     _extras,
      purchaseSource: _source,
      verified:       widget.fromScan ? true : null,
    );
    if (!mounted) return;
    // A secret-code match returns a marker LegoSet (see
    // CollectionProvider.addSet) instead of actually adding a set --
    // surface it here rather than popping immediately, since the
    // ScaffoldMessenger showing the toast goes away with this route the
    // instant it's popped and the player would never see it.
    if (result.id == 'secret') {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎉 Secret unlocked: ${result.name}!'),
      ));
      return;
    }
    BrikHaptics.medium();
    // Value signal at add-time is retail (or paid, if retail's unknown) --
    // there's no eBay price yet for a set added this instant. Fired before
    // popping so it uses this route's still-mounted context; Overlay is
    // shared app-wide by Navigator, so the celebration survives the pop
    // and plays over whatever screen you land back on.
    showSetAddedCelebration(context, value: result.retail ?? result.paid);
    Navigator.pop(context);
  }

  double get _insiderPts {
    final paid = double.tryParse(_cPaid.text.replaceAll(',', '')) ?? 0;
    return _source.earnsInsiderPoints ? paid * 0.05 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Form(
        key: _form,
        child: CustomScrollView(slivers: [

          // ── Header (always yellow — brand mark) ──────────────────────────
          SliverToBoxAdapter(
            child: StudBackground(
              color: BT.yellow,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: BT.ink, width: BT.bw)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: BT.ink,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: BT.yellow, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Add Set', style: BT.display(size: 26, color: bt.tx)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: BT.ink,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(BT.yellow),
                                  ))
                              : Text('Save',
                                  style: BT.display(size: 16,
                                      color: BT.yellow)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Rebrickable preview ───────────────────────────────────
                if (_rb != null) ...[
                  Text('Found on Rebrickable',
                      style: BT.mono(size: 9, color: bt.tx3)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                      boxShadow: [BoxShadow(color: bt.shadowColor,
                          offset: const Offset(3, 3))],
                    ),
                    child: Row(children: [
                      if (_rb!['set_img_url'] != null)
                        Container(
                          width: 58, height: 58,
                          decoration: BoxDecoration(
                            color: bt.surface2,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: bt.cardBorder,
                                width: BT.bw),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                              imageUrl: _rb!['set_img_url'] as String,
                              fit: BoxFit.contain),
                        ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_rb!['name'] as String? ?? '',
                            style: BT.body(size: 14, color: bt.tx), maxLines: 2),
                        const SizedBox(height: 3),
                        Text(
                          '${_rb!['set_num']} · ${_rb!['year'] ?? '?'} · '
                          '${_rb!['num_parts'] ?? '?'} pcs',
                          style: BT.mono(size: 9, color: bt.tx3),
                        ),
                        if (_rb!['theme_name'] != null) ...[
                          const SizedBox(height: 5),
                          ThemeBadge(
                              theme: (_rb!['theme_name'] as String)
                                  .split(' > ')
                                  .first,
                              compact: true),
                        ],
                      ])),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: BT.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: BT.ink, width: BT.bw),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 14),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Set number ────────────────────────────────────────────
                _field(bt, 'Set number', _cNum,
                  hint: 'e.g. 75379',
                  keyboard: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  suffix: _looking
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(BT.green)))
                      : _rb != null
                          ? const Icon(Icons.check_circle,
                              color: BT.green, size: 18)
                          : null,
                ),

                _field(bt, 'Name', _cName,
                    hint: 'Auto-fills from Rebrickable'),

                // ── Condition ─────────────────────────────────────────────
                Text('Condition', style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 6),
                Row(children: [
                  _condBtn(bt, 'sealed', '📦 Sealed / NIB'),
                  const SizedBox(width: 10),
                  _condBtn(bt, 'open',   '🔓 Open box'),
                ]),

                // ── Open extras ───────────────────────────────────────────
                if (_status == 'open') ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final r =
                          await OpenExtrasSheet.show(context, _extras);
                      if (r != null) setState(() => _extras = r);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: bt.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: bt.cardBorder, width: BT.bw),
                        boxShadow: [BoxShadow(color: bt.shadowColor,
                            offset: const Offset(2, 2))],
                      ),
                      child: Row(children: [
                        Text(_extras.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Box & manual', style: BT.body(size: 14, color: bt.tx)),
                          Text(_extras.label,
                              style: BT.mono(size: 10, color: bt.tx3)),
                        ])),
                        Icon(Icons.chevron_right,
                            color: bt.txMuted, size: 18),
                      ]),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Prices ────────────────────────────────────────────────
                Row(children: [
                  Expanded(child: _field(bt, 'MSRP / Retail', _cRet,
                      hint: '0.00', prefix: '\$',
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _field(bt, 'Price paid', _cPaid,
                      hint: '0.00', prefix: '\$',
                      keyboard: const TextInputType.numberWithOptions(
                          decimal: true))),
                ]),

                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 80,
                      child: _field(bt, 'Qty', _cQty,
                          hint: '1', keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(bt, 'Notes', _cNotes,
                      hint: 'e.g. Target clearance…')),
                ]),

                // ── Purchase source ───────────────────────────────────────
                Text('Where purchased',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final r =
                        await PurchaseSourceSheet.show(context, _source);
                    if (r != null) setState(() => _source = r);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _source.earnsInsiderPoints
                          ? BT.yellowBg : bt.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _source.earnsInsiderPoints
                            ? BT.yellow3 : bt.cardBorder,
                        width: BT.bw,
                      ),
                      boxShadow: _source.earnsInsiderPoints
                          ? [const BoxShadow(
                              color: BT.yellow3, offset: Offset(2, 2))]
                          : [BoxShadow(color: bt.shadowColor,
                              offset: const Offset(2, 2))],
                    ),
                    child: Row(children: [
                      Text(_source.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_source.label, style: BT.body(size: 14, color: bt.tx)),
                        if (_source.earnsInsiderPoints)
                          Text(
                            _insiderPts > 0
                                ? '\$${_insiderPts.toStringAsFixed(2)} Insider points (5%)'
                                : '5% back in Insider points',
                            style: BT.mono(size: 9, color: BT.gold),
                          ),
                        if (!_source.earnsInsiderPoints)
                          Text('Tap to change',
                              style: BT.mono(size: 9, color: bt.tx3)),
                      ])),
                      Icon(Icons.chevron_right,
                          color: bt.txMuted, size: 18),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // ── CTA ───────────────────────────────────────────────────
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: BT.ink,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BT.ink, width: BT.bw),
                      boxShadow: [BoxShadow(color: bt.shadowColor,
                          offset: const Offset(3, 3))],
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      if (_saving)
                        const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(BT.yellow)))
                      else ...[
                        const Icon(Icons.add, color: BT.yellow, size: 20),
                        const SizedBox(width: 8),
                        Text('Add to BrikStax',
                            style: BT.body(size: 16, color: BT.yellow)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _condBtn(BrikStaxColors bt, String value, String label) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() {
        _status = value;
        if (value == 'sealed') _extras = const OpenExtras();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _status == value ? BT.ink : bt.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: _status == value
              ? []
              : [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: BT.body(size: 13,
                color: _status == value ? BT.yellow : bt.tx)),
      ),
    ),
  );

  Widget _field(BrikStaxColors bt, String label, TextEditingController ctrl, {
    String? hint, String? prefix, Widget? suffix,
    TextInputType? keyboard, String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: BT.mono(size: 9, color: bt.tx3)),
          const SizedBox(height: 5),
          Container(
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
            ),
            child: TextFormField(
              controller: ctrl,
              keyboardType: keyboard,
              validator: validator,
              style: BT.mono(size: 14, color: bt.tx),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: BT.mono(size: 14, color: bt.txMuted),
                prefixText: prefix,
                prefixStyle: BT.mono(size: 14, color: bt.txMuted),
                suffixIcon: suffix != null
                    ? Padding(padding: const EdgeInsets.only(right: 10),
                        child: suffix)
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: BT.yellow3, width: BT.bw),
                ),
                fillColor: bt.cardBg,
                filled: true,
              ),
            ),
          ),
        ]),
      );
}
