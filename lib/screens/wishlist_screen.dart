// lib/screens/wishlist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/wishlist_item.dart';
import '../providers/collection.dart';
import '../services/affiliate_links.dart';
import '../services/api.dart';
import '../services/wishlist_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override State<WishlistScreen> createState() => _State();
}

class _State extends State<WishlistScreen> {
  bool _checking = false;

  Future<void> _refreshPrices() async {
    setState(() => _checking = true);
    final alerts = await WishlistService.instance.checkAll();
    if (!mounted) return;
    setState(() => _checking = false);
    if (alerts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(alerts.first.message),
        duration: const Duration(seconds: 3),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Prices updated — nothing at target yet'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt  = context.bt;
    final svc = context.watch<WishlistService>();
    final items = svc.items;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: bt.surface,
            border: Border(
                bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Text('Wishlist', style: BT.display(size: 26)),
                const Spacer(),
                if (items.isNotEmpty)
                  GestureDetector(
                    onTap: _checking ? null : _refreshPrices,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bt.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: bt.cardBorder, width: BT.bw),
                      ),
                      child: _checking
                          ? SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      bt.tx)))
                          : Text('Check prices',
                              style: BT.mono(size: 9, color: bt.tx)),
                    ),
                  ),
              ]),
            ),
          ),
        ),

        // ── Free-tier indicator ─────────────────────────────────────────
        if (!svc.isPro)
          Container(
            width: double.infinity,
            color: BT.yellowBg,
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            child: Text(
              svc.atCap
                  ? '★ Free limit reached (${WishlistService.freeTierCap}). Upgrade to Pro for unlimited wishlist + auto alerts.'
                  : '${svc.remainingFreeSlots} of ${WishlistService.freeTierCap} free slots left · Pro = unlimited + auto alerts',
              style: BT.mono(size: 9, color: BT.tx2),
            ),
          ),

        Expanded(
          child: items.isEmpty
              ? _emptyState(bt)
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _wishCard(bt, items[i]),
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wishlist_fab',
        onPressed: svc.atCap ? _showUpgrade : _showAdd,
        backgroundColor: BT.yellow,
        foregroundColor: BT.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BT.ink, width: BT.bw),
        ),
        elevation: 0,
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }

  Widget _emptyState(BrikStaxColors bt) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🎯', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Your wishlist is empty', style: BT.display(size: 22)),
        const SizedBox(height: 8),
        Text(
          'Add sets you want, set a target price, and BrikStax will tell you '
          'when they hit it. Tap + to start.',
          style: BT.mono(size: 11, color: bt.tx2),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );

  Widget _wishCard(BrikStaxColors bt, WishlistItem w) {
    final atTarget = w.atOrBelowTarget;
    final pct = w.percentOffRetail;
    return Dismissible(
      key: ValueKey(w.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: BT.redBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: BT.red),
      ),
      onDismissed: (_) => WishlistService.instance.remove(w.id),
      child: GestureDetector(
        onTap: () => _showEdit(w),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: atTarget ? const Color(0xFFE1F5EE) : bt.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: atTarget ? BT.green : bt.cardBorder, width: BT.bw),
            boxShadow: [BoxShadow(color: bt.shadowColor,
                offset: const Offset(2, 2))],
          ),
          child: Row(children: [
            if (w.imageUrl != null)
              Container(
                width: 52, height: 52,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(w.imageUrl!, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.widgets_outlined,
                            color: bt.txMuted, size: 22)),
              ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name.isNotEmpty ? w.name : 'Set ${w.num}',
                    style: BT.body(size: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('#${w.num}',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const SizedBox(height: 5),
                Row(children: [
                  if (w.currentPrice != null)
                    Text('\$${w.currentPrice!.toStringAsFixed(0)}',
                        style: BT.body(size: 14,
                            color: atTarget ? BT.green : bt.tx))
                  else
                    Text('— check price',
                        style: BT.mono(size: 10, color: bt.txMuted)),
                  if (w.targetPrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                        'target \$${w.targetPrice!.toStringAsFixed(0)}',
                        style: BT.mono(size: 9, color: bt.tx3)),
                  ],
                  const Spacer(),
                  if (atTarget)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: BT.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('AT TARGET',
                          style: BT.mono(size: 8,
                              color: Colors.white)),
                    )
                  else if (pct != null && pct > 0)
                    Text('-$pct%',
                        style: BT.mono(size: 10, color: BT.green)),
                ]),
                if (w.progressToTarget != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: w.progressToTarget,
                      backgroundColor: bt.surface2,
                      valueColor: AlwaysStoppedAnimation(
                          atTarget ? BT.green : BT.gold),
                      minHeight: 5,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _buyLinks(bt, w),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  // Search links, not a specific listing -- there's no ASIN/eBay item id
  // for an arbitrary set, just a set number + name. Both carry BrikStax's
  // own affiliate tag (see services/affiliate_links.dart). Each chip is
  // its own GestureDetector nested inside the card's (onTap: _showEdit) --
  // Flutter's gesture arena resolves the tap to whichever recognizer is
  // innermost, so tapping a chip opens the link instead of the edit sheet.
  Widget _buyLinks(BrikStaxColors bt, WishlistItem w) => Row(children: [
    Expanded(child: _buyChip(bt, 'Amazon', BT.orange,
        () => _openBuyLink(amazonSearchUrl(w.num, w.name)))),
    const SizedBox(width: 6),
    Expanded(child: _buyChip(bt, 'eBay', BT.blue, () => _openEbayLink(w))),
  ]);

  // Tries a real, currently-active listing first (Api.fetchEbayProductUrl,
  // the official eBay Browse API) and falls back to the plain search link
  // whenever that comes back null -- including the common case where
  // EBAY_CLIENT_ID/SECRET just aren't configured on the Worker yet (see
  // handleEbayProduct's doc comment). No loading indicator: worst case
  // this takes a moment before the browser opens, same as any other
  // external-link tap elsewhere in the app.
  Future<void> _openEbayLink(WishlistItem w) async {
    final direct = await Api.instance.fetchEbayProductUrl(w.num, w.name);
    await _openBuyLink(direct ?? ebaySearchUrl(w.num, w.name));
  }

  Widget _buyChip(BrikStaxColors bt, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: bt.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: bt.cardBorder, width: 1),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.open_in_new, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label, style: BT.mono(size: 10, weight: FontWeight.w700, color: color)),
          ]),
        ),
      );

  // Real user feedback 2026-08-18: opening in a browser instead of the
  // native app (Amazon especially -- its own app is inconsistent about
  // claiming search-page deep links, only reliably claiming product pages,
  // which this app can't build without an ASIN) reads as unwanted extra
  // friction, not a fair tradeoff. externalNonBrowserApplication tells
  // Android to prefer a non-browser handler when one exists -- but unlike
  // externalApplication, it can fail to open ANYTHING if no such handler
  // claims the URL, so it's tried first with the old, always-reliable
  // browser-capable mode as an automatic fallback if that happens. A tap
  // should never end up doing nothing.
  Future<void> _openBuyLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) return;
    bool openedApp = false;
    try {
      openedApp = await launchUrl(
          uri, mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {}
    if (!openedApp) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Add sheet ─────────────────────────────────────────────────────────────
  void _showAdd() {
    final bt = context.bt;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => const _AddWishSheet(),
    );
  }

  // ── Edit sheet ───────────────────────────────────────────────────────────
  void _showEdit(WishlistItem w) {
    final bt = context.bt;
    final targetCtrl = TextEditingController(
        text: w.targetPrice?.toStringAsFixed(0) ?? '');
    bool nTarget = w.notifyOnTarget;
    bool nDrop   = w.notifyOnDrop;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) =>
          StatefulBuilder(builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: bt.cardBorder,
                  borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(w.name.isNotEmpty ? w.name : 'Set ${w.num}',
                style: BT.display(size: 20)),
            Text('#${w.num}',
                style: BT.mono(size: 10, color: bt.tx3)),
            const SizedBox(height: 14),
            _SheetField(
              label: 'Target price \$',
              controller: targetCtrl,
              hint: '700',
              keyboard:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: BT.green,
              title: Text('Alert at target price',
                  style: BT.body(size: 13)),
              value: nTarget,
              onChanged: (v) => setSheet(() => nTarget = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: BT.green,
              title: Text('Alert on big price drop',
                  style: BT.body(size: 13)),
              subtitle: Text('When it falls 10%+ since last check',
                  style: BT.mono(size: 9, color: bt.tx3)),
              value: nDrop,
              onChanged: (v) => setSheet(() => nDrop = v),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                await WishlistService.instance.update(w.copyWith(
                  targetPrice:
                      double.tryParse(targetCtrl.text.trim()),
                  notifyOnTarget: nTarget,
                  notifyOnDrop: nDrop,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 8),
            Center(child: TextButton(
              onPressed: () {
                WishlistService.instance.remove(w.id);
                Navigator.pop(ctx);
              },
              child: Text('Remove from wishlist',
                  style: BT.body(size: 13, color: BT.red)),
            )),
          ]),
        ),
      )),
    );
  }

  void _showUpgrade() {
    final bt = context.bt;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bt.cardBg,
        title: Text('Go Pro', style: BT.display(size: 22)),
        content: Text(
          'You\'ve hit the free wishlist limit of '
          '${WishlistService.freeTierCap}. '
          'BrikStax Pro unlocks an unlimited wishlist and automatic price '
          'alerts, so you never miss a deal on a set you want.',
          style: BT.mono(size: 12, color: bt.tx2),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Maybe later',
                  style: BT.body(size: 14, color: bt.tx2))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Learn about Pro'),
          ),
        ],
      ),
    );
  }
}

// ── Add sheet widget ──────────────────────────────────────────────────────────
class _AddWishSheet extends StatefulWidget {
  const _AddWishSheet();
  @override State<_AddWishSheet> createState() => _AddWishSheetState();
}

class _AddWishSheetState extends State<_AddWishSheet> {
  final _numCtrl    = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _retailCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();

  bool _looking = false;
  bool _busy    = false;
  bool _found   = false;
  Map<String, dynamic>? _lookupData;

  @override
  void initState() {
    super.initState();
    _numCtrl.addListener(_onNumChange);
  }

  @override
  void dispose() {
    _numCtrl.removeListener(_onNumChange);
    for (final c in [_numCtrl, _nameCtrl, _retailCtrl, _targetCtrl]) {
      c.dispose();
    }
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
        _lookupData = d;
        _found = true;
        final name = d['name'] as String? ?? '';
        if (name.isNotEmpty && _nameCtrl.text.trim().isEmpty) {
          _nameCtrl.text = name;
        }
      }
    });
    if (d != null) {
      _fetchRetail(d['set_num'] as String? ?? num);
    }
  }

  Future<void> _fetchRetail(String num) async {
    try {
      final price = await Api.instance.fetchRetail(num);
      if (mounted && price != null && _retailCtrl.text.trim().isEmpty) {
        setState(() => _retailCtrl.text = price.toStringAsFixed(2));
      }
    } catch (_) {}
  }

  Future<void> _add() async {
    final n = _numCtrl.text.trim();
    if (n.isEmpty) return;
    setState(() => _busy = true);

    final d = _lookupData;
    final item = WishlistItem(
      id: 'wish_${DateTime.now().millisecondsSinceEpoch}',
      num: n,
      name: _nameCtrl.text.trim(),
      imageUrl: d?['set_img_url'] as String?,
      theme: d?['theme_name'] as String?,
      retailPrice: double.tryParse(
          _retailCtrl.text.replaceAll(',', '').trim()),
      targetPrice: double.tryParse(
          _targetCtrl.text.replaceAll(',', '').trim()),
      addedAt: DateTime.now(),
    );

    final ok = await WishlistService.instance.add(item);
    if (!mounted) return;
    Navigator.pop(context);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Free wishlist limit reached — upgrade to Pro'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20, right: 20, top: 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: bt.cardBorder,
                borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Add to wishlist', style: BT.display(size: 22)),
          const SizedBox(height: 14),

          _SheetField(
            label: 'Set number',
            controller: _numCtrl,
            hint: 'e.g. 75192',
            keyboard: TextInputType.number,
            digitsOnly: true,
            suffix: _looking
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(BT.green)))
                : _found
                    ? const Icon(Icons.check_circle,
                        color: BT.green, size: 18)
                    : null,
          ),
          _SheetField(
            label: 'Name',
            controller: _nameCtrl,
            hint: 'Auto-fills from set number',
          ),
          Row(children: [
            Expanded(child: _SheetField(
              label: 'Retail \$',
              controller: _retailCtrl,
              hint: 'auto',
              keyboard:
                  const TextInputType.numberWithOptions(decimal: true),
            )),
            const SizedBox(width: 10),
            Expanded(child: _SheetField(
              label: 'Target \$',
              controller: _targetCtrl,
              hint: '700',
              keyboard:
                  const TextInputType.numberWithOptions(decimal: true),
            )),
          ]),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _add,
            child: _busy
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(BT.yellow)))
                : const Text('Add to wishlist'),
          ),
        ]),
      ),
    );
  }
}

// ── Shared field widget for the sheets ───────────────────────────────────────
class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final bool digitsOnly;
  final Widget? suffix;
  const _SheetField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
    this.digitsOnly = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: BT.mono(size: 9, color: bt.tx3)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: bt.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            style: BT.body(size: 14, color: bt.tx),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: BT.mono(size: 12, color: bt.txMuted),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: suffix)
                  : null,
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              fillColor: bt.cardBg,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
            ),
          ),
        ),
      ]),
    );
  }
}
