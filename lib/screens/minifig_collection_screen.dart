// lib/screens/minifig_collection_screen.dart
//
// "My Minifigs" -- list/grid of MinifigService's collection, owned/wanted
// filter, search. Simpler than InventoryScreen on purpose (no theme/sort
// complexity for v1): the entry point into this whole feature is a single
// icon button on InventoryScreen's own header, not a bottom-nav tab (a
// deliberate placement decision -- see MEMORY/plan notes -- so this screen
// stays a lightweight, self-contained corner of the existing Sets tab).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/minifig_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import 'minifig_detail_screen.dart';
import 'minifig_lookup_screen.dart';

class MinifigCollectionScreen extends StatefulWidget {
  const MinifigCollectionScreen({super.key});
  @override State<MinifigCollectionScreen> createState() => _State();
}

class _State extends State<MinifigCollectionScreen> {
  String _q = '';
  String _filter = 'all'; // all | owned | wanted

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final svc = context.watch<MinifigService>();

    var items = svc.items;
    if (_filter != 'all') items = items.where((m) => m.status == _filter).toList();
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      items = items.where((m) =>
          m.name.toLowerCase().contains(q) || m.figNum.toLowerCase().contains(q)).toList();
    }

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
              Expanded(child: Text('My Minifigs', style: BT.display(size: 24, color: bt.tx))),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const MinifigLookupScreen())),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: BT.yellow,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: BT.ink, width: BT.bw),
                    boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
                  ),
                  child: const Icon(Icons.add, color: BT.ink, size: 20),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  style: BT.mono(size: 13, color: bt.tx),
                  decoration: InputDecoration(
                    hintText: 'Search my minifigs…',
                    hintStyle: BT.mono(size: 12, color: bt.txMuted),
                    prefixIcon: Icon(Icons.search, size: 18, color: bt.txMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    fillColor: bt.cardBg,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                for (final f in const ['all', 'owned', 'wanted'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _filter == f ? bt.tx : bt.cardBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: bt.cardBorder, width: BT.bw),
                        ),
                        child: Text(f == 'all' ? 'All' : f == 'owned' ? 'Owned' : 'Wanted',
                            style: BT.body(size: 12, weight: FontWeight.w600,
                                color: _filter == f ? bt.surface : bt.tx)),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        svc.count == 0
                            ? 'No minifigs yet — tap + to look one up.'
                            : 'No minifigs match this filter.',
                        style: BT.body(size: 13, color: bt.tx2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = items[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => MinifigDetailScreen(figNum: m.figNum))),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bt.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: bt.cardBorder, width: BT.bw),
                          ),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: bt.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: bt.cardBorder, width: BT.bw),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: m.imageUrl != null
                                  ? CachedNetworkImage(imageUrl: m.imageUrl!, fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(Icons.emoji_people, color: bt.txMuted, size: 18))
                                  : Icon(Icons.emoji_people, color: bt.txMuted, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.name.isNotEmpty ? m.name : m.figNum,
                                  style: BT.body(size: 13, weight: FontWeight.w700, color: bt.tx),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                [m.figNum, if (m.qty > 1) 'x${m.qty}'].join(' · '),
                                style: BT.mono(size: 10, color: bt.tx3),
                              ),
                            ])),
                            if (m.hasValue)
                              Text('\$${m.valueUsd!.toStringAsFixed(0)}',
                                  style: BT.body(size: 13, weight: FontWeight.w700, color: BT.green))
                            else
                              Icon(Icons.chevron_right, color: bt.txMuted, size: 18),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
