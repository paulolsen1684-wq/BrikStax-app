// lib/screens/inventory.dart — BrikStax Brick UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lego_set.dart';
import '../providers/collection.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/set_card.dart';
import 'add_set.dart';
import 'set_detail.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override State<InventoryScreen> createState() => _State();
}

class _State extends State<InventoryScreen> {
  final _search = TextEditingController();
  String _q     = '';
  String _cond  = 'all';
  String _sort  = 'added';
  String _theme = 'all';

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Consumer<CollectionProvider>(
      builder: (_, col, __) {
        var sets = col.sets.toList();

        // Filter
        if (_q.isNotEmpty) {
          final q = _q.toLowerCase();
          sets = sets.where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.num.contains(q) ||
              (s.theme?.toLowerCase().contains(q) ?? false)).toList();
        }
        if (_cond != 'all')  sets = sets.where((s) => s.status == _cond).toList();
        if (_theme != 'all') sets = sets.where((s) =>
            (s.theme?.split(' > ').first ?? '') == _theme).toList();

        // Sort
        switch (_sort) {
          case 'name':    sets.sort((a,b) => a.name.compareTo(b.name)); break;
          case 'roi':     sets.sort((a,b) => (b.roi ?? -999).compareTo(a.roi ?? -999)); break;
          case 'value':   sets.sort((a,b) => (b.ebayAvg ?? 0).compareTo(a.ebayAvg ?? 0)); break;
          case 'year':    sets.sort((a,b) => (b.year ?? 0).compareTo(a.year ?? 0)); break;
          case 'pieces':  sets.sort((a,b) => (b.pieces ?? 0).compareTo(a.pieces ?? 0)); break;
          default:        sets.sort((a,b) => b.addedAt.compareTo(a.addedAt));
        }

        final themes = col.sets
            .map((s) => s.theme?.split(' > ').first ?? '')
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        return CustomScrollView(slivers: [

          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bt.surface,
                border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Row(children: [
                      Text('BrikStax', style: BT.display(size: 26)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const AddSetScreen())),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: BT.yellow,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: BT.ink, width: BT.bw),
                            boxShadow: BT.shadowSm,
                          ),
                          child: const Icon(Icons.add, color: BT.ink, size: 20),
                        ),
                      ),
                    ]),
                  ),

                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bt.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: bt.cardBorder, width: BT.bw),
                        boxShadow: [BoxShadow(color: bt.shadowColor,
                            offset: const Offset(3, 3))],
                      ),
                      child: TextField(
                        controller: _search,
                        onChanged: (v) => setState(() => _q = v),
                        style: BT.mono(size: 13, color: bt.tx),
                        decoration: InputDecoration(
                          hintText: 'Search sets, themes…',
                          hintStyle: BT.mono(size: 13, color: bt.txMuted),
                          prefixIcon: Icon(Icons.search,
                              color: bt.txMuted, size: 18),
                          suffixIcon: _q.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: bt.txMuted, size: 16),
                                  onPressed: () => setState(() {
                                    _q = '';
                                    _search.clear();
                                  }),
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ),

                  // Filter chips
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _chip(context, 'All ${col.count}', _cond == 'all',
                            () => setState(() => _cond = 'all')),
                        _chip(context, 'Sealed', _cond == 'sealed',
                            () => setState(() => _cond = 'sealed')),
                        _chip(context, 'Open', _cond == 'open',
                            () => setState(() => _cond = 'open')),
                        const SizedBox(width: 8),
                        VerticalDivider(width: 1,
                            color: bt.cardBorder, thickness: 1),
                        const SizedBox(width: 8),
                        _chip(context, 'Gainers ↑', _sort == 'roi',
                            () => setState(() => _sort =
                                _sort == 'roi' ? 'added' : 'roi'),
                            activeColor: BT.green),
                        _chip(context, 'Newest', _sort == 'year',
                            () => setState(() => _sort =
                                _sort == 'year' ? 'added' : 'year')),
                        _chip(context, 'Value', _sort == 'value',
                            () => setState(() => _sort =
                                _sort == 'value' ? 'added' : 'value')),
                        _chip(context, 'A–Z', _sort == 'name',
                            () => setState(() => _sort =
                                _sort == 'name' ? 'added' : 'name')),
                        ...themes.map((t) => _chip(
                          context,
                          t.split(' ').first,
                          _theme == t,
                          () => setState(() =>
                              _theme = _theme == t ? 'all' : t),
                          activeColor: themeColor(t),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),

          // ── Set list ─────────────────────────────────────────────────────
          if (sets.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off, size: 48, color: bt.txMuted),
                  const SizedBox(height: 12),
                  Text('No sets found',
                      style: BT.body(size: 16, color: bt.txMuted)),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = sets[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Dismissible(
                      key: Key(s.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: BT.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      confirmDismiss: (_) => showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: bt.cardBg,
                          title: Text('Remove ${s.name}?',
                              style: BT.display(size: 20)),
                          content: Text('This cannot be undone.',
                              style: BT.mono(size: 12)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel',
                                  style: BT.body(size: 14, color: bt.tx2)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: BT.red,
                                  foregroundColor: Colors.white),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => col.remove(s.id),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    SetDetailScreen(setId: s.id))),
                        child: SetCard(set: s),
                      ),
                    ),
                  );
                },
                childCount: sets.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ]);
      },
    );
  }

  Widget _chip(BuildContext context, String label, bool active, VoidCallback onTap,
      {Color? activeColor}) {
    final bt = context.bt;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? (activeColor ?? BT.ink) : bt.cardBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: active ? (activeColor ?? BT.ink) : bt.cardBorder,
              width: BT.bw,
            ),
            boxShadow: active
                ? []
                : [BoxShadow(color: bt.shadowColor, offset: const Offset(2, 2))],
          ),
          child: Text(label,
              style: BT.mono(
                  size: 9,
                  color: active ? Colors.white : bt.tx)),
        ),
      ),
    );
  }
}
