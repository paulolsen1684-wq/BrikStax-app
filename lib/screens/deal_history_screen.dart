// lib/screens/deal_history_screen.dart
//
// Full list of every live (non-expired) deal posted via Discord's /deal,
// /amazondeal, /ebaydeal commands -- until this screen existed, DealsService
// was only ever consumed by DealOfDayCard, which shows exactly one deal, so
// everything posted beyond the single most-recent one was live on the
// server but invisible anywhere in the app. This is that missing list.
//
// Always force-refreshes on open rather than trusting DealsService's 6h
// in-memory cache -- a "history" screen someone deliberately opened should
// show current state, not up to 6h stale.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/deals_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';

class DealHistoryScreen extends StatefulWidget {
  const DealHistoryScreen({super.key});
  @override State<DealHistoryScreen> createState() => _State();
}

class _State extends State<DealHistoryScreen> {
  List<Deal>? _deals;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _error = null; });
    try {
      final deals = await DealsService.instance.fetch(force: true);
      if (mounted) setState(() => _deals = deals);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        title: Text('Deal History', style: BT.display(size: 20, color: bt.tx)),
        backgroundColor: bt.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: bt.tx),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _deals == null
            ? Center(child: _error != null
                ? Text('Couldn\'t load deals: $_error',
                    style: BT.body(size: 13, color: BT.red),
                    textAlign: TextAlign.center)
                : const CircularProgressIndicator(color: BT.yellow))
            : _deals!.isEmpty
                ? Center(child: Text('No live deals right now',
                    style: BT.body(size: 14, color: bt.txMuted)))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: BT.yellow,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: _deals!.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DealTile(deal: _deals![i]),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _DealTile extends StatelessWidget {
  final Deal deal;
  const _DealTile({required this.deal});

  // Matches DealOfDayCard's own _open() exactly -- same launch pattern.
  Future<void> _open() async {
    final uri = Uri.tryParse(deal.url);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final off = deal.percentOff;
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (deal.imageUrl != null)
            Container(
              width: 56, height: 56,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(deal.imageUrl!, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image_not_supported, color: bt.txMuted, size: 20)),
            ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(deal.title,
                  style: BT.body(size: 13, weight: FontWeight.w700, color: bt.tx),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (deal.featured) ...[
                const SizedBox(width: 6),
                const Text('⭐', style: TextStyle(fontSize: 12)),
              ],
            ]),
            if (deal.setNum != null || deal.retailer != null)
              Text(
                [if (deal.setNum != null) '#${deal.setNum}', if (deal.retailer != null) deal.retailer!]
                    .join(' · '),
                style: BT.mono(size: 9, color: bt.tx3),
              ),
            const SizedBox(height: 4),
            Row(children: [
              if (deal.dealPrice != null)
                Text('\$${deal.dealPrice!.toStringAsFixed(2)}',
                    style: BT.display(size: 15, color: BT.green)),
              if (deal.retailPrice != null && deal.dealPrice != null) ...[
                const SizedBox(width: 6),
                Text('\$${deal.retailPrice!.toStringAsFixed(2)}',
                    style: BT.mono(size: 10, color: bt.txMuted)
                        .copyWith(decoration: TextDecoration.lineThrough)),
              ],
              const Spacer(),
              if (off != null && off > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: BT.greenBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BT.green, width: BT.bw),
                  ),
                  child: Text('-$off%', style: BT.display(size: 11, color: BT.green)),
                )
              else if (off != null && off < 0)
                Text('above retail', style: BT.mono(size: 9, color: BT.red)),
            ]),
            if (deal.expires != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Expires ${deal.expires}',
                    style: BT.mono(size: 8, color: bt.tx3)),
              ),
          ])),
        ]),
      ),
    );
  }
}
