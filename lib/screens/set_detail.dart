// lib/screens/set_detail.dart — BrikStax Brick UI
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/lego_set.dart';
import '../providers/collection.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/atoms.dart';
import '../widgets/sheets.dart';

class SetDetailScreen extends StatefulWidget {
  final String setId;
  const SetDetailScreen({super.key, required this.setId});
  @override State<SetDetailScreen> createState() => _State();
}

class _State extends State<SetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override void dispose()   { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Consumer<CollectionProvider>(
      builder: (_, col, __) {
        final matches = col.sets.where((x) => x.id == widget.setId);
        if (matches.isEmpty) {
          return Scaffold(
            backgroundColor: bt.surface,
            appBar: AppBar(
                title: Text('Set not found', style: BT.display(size: 20, color: bt.tx))),
            body: Center(child: Text('This set could not be found.',
                style: BT.mono(size: 13))),
          );
        }
        final s  = matches.first;
        final tc = themeColor(s.theme ?? '');

        return Scaffold(
          backgroundColor: bt.surface,
          body: CustomScrollView(slivers: [

            // ── Hero ────────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: tc,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: _HeroBg(s: s, tc: tc),
              ),
            ),

            // ── Price grid ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: bt.cardBg,
                  border: Border(
                      bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
                ),
                child: Row(children: [
                  _PTile('Retail', s.retail),
                  _PTile('Paid',   s.paid),
                  _PTile('eBay',   s.ebayAvg, color: BT.green,
                      isFallback: s.ebayAvgIsFallback),
                  _RoiTile(s.roi),
                ]),
              ),
            ),

            // ── Retirement window banner ───────────────────────────────────
            if (s.inRetirementWindow)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BT.greenBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BT.green, width: BT.bw),
                  ),
                  child: Row(children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        'In its price-climb window',
                        style: BT.body(size: 13, color: BT.green,
                            weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.monthsSinceRetirement} months since retirement — this is '
                        'the ~18-24 month stretch where secondary-market prices '
                        'often climb as retail supply dries up.',
                        style: BT.mono(size: 10, color: bt.tx3),
                      ),
                    ])),
                  ]),
                ),
              ),

            // ── Tab bar ─────────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabDelegate(
                bt,
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Prices'),
                    Tab(text: 'Chart'),
                    Tab(text: 'Details'),
                  ],
                  indicatorColor: BT.yellow,
                  indicatorWeight: 3,
                  labelStyle: BT.mono(size: 11, weight: FontWeight.w500),
                  unselectedLabelStyle: BT.mono(size: 11),
                  labelColor: bt.tx,
                  unselectedLabelColor: bt.txMuted,
                  dividerColor: bt.cardBorder,
                ),
              ),
            ),

            SliverFillRemaining(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PricesTab(s: s),
                  _ChartTab(s: s),
                  _DetailsTab(s: s),
                ],
              ),
            ),
          ]),

          floatingActionButton: GestureDetector(
            onTap: () => _fetchEbay(context, col),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: BoxDecoration(
                color: BT.yellow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadow,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh, color: BT.ink, size: 18),
                const SizedBox(width: 6),
                Text('Refresh eBay', style: BT.body(size: 14, color: bt.tx)),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _fetchEbay(BuildContext ctx, CollectionProvider col) {
    col.refreshEbay(
        onError: (e) => ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(e))));
  }
}

// ── Hero background ───────────────────────────────────────────────────────────
class _HeroBg extends StatelessWidget {
  final LegoSet s;
  final Color tc;
  const _HeroBg({required this.s, required this.tc});

  @override
  Widget build(BuildContext context) =>
      Stack(fit: StackFit.expand, children: [
        StudBackground(color: tc, child: const SizedBox.expand()),
        if (s.imageUrl != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(.25), BlendMode.darken),
            child: CachedNetworkImage(
              imageUrl: s.imageUrl!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black38],
            ),
          ),
        ),
        Positioned(
          bottom: 14, left: 16, right: 16,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, children: [
              CondBadge(s.status),
              if (s.theme != null)
                ThemeBadge(theme: s.theme!.split(' > ').first),
              if (s.retired)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: Text('Retired',
                      style: BT.mono(size: 8,
                          color: Colors.orange,
                          weight: FontWeight.w500)),
                ),
              if (s.inRetirementWindow)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: BT.green.withOpacity(.2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: BT.green, width: 1.5),
                  ),
                  child: Text('🔥 Price climb window',
                      style: BT.mono(size: 8,
                          color: BT.green,
                          weight: FontWeight.w500)),
                ),
            ]),
            const SizedBox(height: 6),
            Text(s.name,
                style: BT.display(size: 22, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${s.num}  ·  ${s.year ?? '?'}  ·  '
              '${s.pieces != null ? '${s.pieces} pcs' : ''}',
              style: BT.mono(size: 11, color: Colors.white60),
            ),
          ]),
        ),
      ]);
}

// ── Price grid tiles ──────────────────────────────────────────────────────────
class _PTile extends StatelessWidget {
  final String  label;
  final double? value;
  final Color?  color;
  final bool    isFallback;
  const _PTile(this.label, this.value, {this.color, this.isFallback = false});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(color: bt.cardBorder, width: BT.bw)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(label, style: BT.mono(size: 8, color: bt.tx3)),
            if (isFallback) ...[
              const SizedBox(width: 4),
              Icon(Icons.warning_amber_rounded,
                  size: 11, color: BT.orange),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            value != null ? '\$${value!.toStringAsFixed(0)}' : '—',
            style: BT.display(size: 22, color: color ?? bt.tx),
          ),
        ]),
      ),
    );
  }
}

class _RoiTile extends StatelessWidget {
  final double? roi;
  const _RoiTile(this.roi);

  @override
  Widget build(BuildContext context) {
    final bt    = context.bt;
    final color = roi == null ? bt.tx3 : roi! >= 0 ? BT.green : BT.red;
    final bg    = roi == null ? bt.surface2
        : roi! >= 0 ? BT.greenBg : BT.redBg;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(color: bg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ROI', style: BT.mono(size: 8, color: bt.tx3)),
          const SizedBox(height: 4),
          Text(
            roi != null
                ? '${roi! >= 0 ? '+' : ''}${roi!.toStringAsFixed(1)}%'
                : '—',
            style: BT.display(size: 22, color: color),
          ),
        ]),
      ),
    );
  }
}

// ── Tab delegate ──────────────────────────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar          tabBar;
  final BrikStaxColors  bt;
  const _TabDelegate(this.bt, this.tabBar);

  @override
  Widget build(_, __, ___) => Container(
    decoration: BoxDecoration(
      color: bt.cardBg,
      border: Border(bottom: BorderSide(color: bt.cardBorder, width: BT.bw)),
    ),
    child: tabBar,
  );
  @override double get maxExtent => 46;
  @override double get minExtent => 46;
  @override bool shouldRebuild(_) => false;
}

// ── Prices tab ────────────────────────────────────────────────────────────────
class _PricesTab extends StatelessWidget {
  final LegoSet s;
  const _PricesTab({required this.s});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
      children: [
        if (s.ebayAvgIsFallback) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BT.orange, width: BT.bw),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: BT.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                s.status == 'sealed'
                    ? 'No sealed listings found — showing open-box price '
                      'instead. ROI above may look worse than reality.'
                    : 'No open-box listings found — showing sealed price '
                      'instead. ROI above may look better than reality.',
                style: BT.mono(size: 10, color: bt.tx),
              )),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (s.ebaySealed != null) ...[
          _sectionLabel(bt, '📦 Sealed / NIB'),
          _priceRow(bt, 'Avg sold', s.ebaySealed),
          const SizedBox(height: 12),
        ],
        if (s.ebayOpen != null) ...[
          _sectionLabel(bt, '🔓 Open box'),
          _priceRow(bt, 'Avg sold', s.ebayOpen),
          const SizedBox(height: 12),
        ],
        if (s.ebaySealed != null && s.ebayOpen != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bt.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
            ),
            child: Row(children: [
              Expanded(child: Text('Sealed premium',
                  style: BT.mono(size: 11, color: bt.tx2))),
              Text(
                '+\$${(s.ebaySealed! - s.ebayOpen!).toStringAsFixed(0)}',
                style: BT.display(size: 20, color: bt.tx),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (s.effectivePaid != null &&
            s.ebayAvg != null &&
            s.roi != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: s.roi! >= 0 ? BT.greenBg : BT.redBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: s.roi! >= 0 ? BT.green : BT.red, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
            ),
            child: Column(children: [
              InfoRow(
                label: 'vs paid',
                value: '${s.ebayAvg! >= s.effectivePaid! ? "+" : ""}'
                    '\$${(s.ebayAvg! - s.effectivePaid!).toStringAsFixed(2)}',
                valueColor:
                    s.ebayAvg! >= s.effectivePaid! ? BT.green : BT.red,
              ),
              InfoRow(
                label: 'ROI',
                value: '${s.roi! >= 0 ? "+" : ""}'
                    '${s.roi!.toStringAsFixed(1)}%',
                valueColor: s.roi! >= 0 ? BT.green : BT.red,
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if ((s.insiderPoints ?? 0) > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BT.yellowBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BT.yellow3, width: BT.bw),
              boxShadow: const [
                BoxShadow(color: BT.yellow3, offset: Offset(2, 2))
              ],
            ),
            child: InfoRow(
              label: '🟡 LEGO Insider points',
              value: '\$${s.insiderPoints!.toStringAsFixed(2)}',
              valueColor: BT.gold,
            ),
          ),
        if (s.ebayFetchedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(child: Text(
              'Updated ${s.ebayFetchedAt!.month}/'
              '${s.ebayFetchedAt!.day}/${s.ebayFetchedAt!.year}',
              style: BT.mono(size: 9, color: bt.txMuted),
            )),
          ),
        if (s.ebaySealed == null && s.ebayOpen == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
            ),
            child: Column(children: [
              Icon(
                  s.sealedZeroResults && s.openZeroResults
                      ? Icons.search_off
                      : Icons.bar_chart,
                  size: 48, color: bt.txMuted),
              const SizedBox(height: 12),
              Text(
                  s.sealedZeroResults && s.openZeroResults
                      ? 'No recent eBay sales found'
                      : 'No price data yet',
                  style: BT.body(size: 14, color: bt.txMuted)),
              const SizedBox(height: 4),
              Text(
                  s.sealedZeroResults && s.openZeroResults
                      ? 'This set hasn\'t sold on eBay recently in either '
                        'condition. Try again later.'
                      : 'Tap Refresh eBay to fetch current prices',
                  style: BT.mono(size: 11, color: bt.tx2),
                  textAlign: TextAlign.center),
            ]),
          ),
      ],
    );
  }

  Widget _sectionLabel(BrikStaxColors bt, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: BT.mono(size: 9,
            color: BT.blue, weight: FontWeight.w500)),
  );

  Widget _priceRow(BrikStaxColors bt, String label, double? value) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor,
              offset: const Offset(2, 2))],
        ),
        child: Row(children: [
          Text(label, style: BT.mono(size: 11, color: bt.tx3)),
          const Spacer(),
          Text(
            value != null ? '\$${value.toStringAsFixed(2)}' : '—',
            style: BT.mono(size: 14,
                color: bt.tx, weight: FontWeight.w500),
          ),
        ]),
      );
}

// ── Chart tab ─────────────────────────────────────────────────────────────────
class _ChartTab extends StatelessWidget {
  final LegoSet s;
  const _ChartTab({required this.s});

  @override
  Widget build(BuildContext context) {
    final bt     = context.bt;
    final hasData = s.ebaySealed != null || s.ebayOpen != null;
    if (!hasData) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart, size: 48, color: bt.txMuted),
        const SizedBox(height: 12),
        Text('No chart data yet',
            style: BT.body(size: 14, color: bt.txMuted)),
        const SizedBox(height: 4),
        Text('Tap Refresh eBay to load prices',
            style: BT.mono(size: 11, color: bt.tx2),
            textAlign: TextAlign.center),
      ]),
    );

    final spots = <FlSpot>[];
    if (s.retail     != null) spots.add(FlSpot(0, s.retail!));
    if (s.paid       != null) spots.add(FlSpot(1, s.paid!));
    if (s.ebayOpen   != null) spots.add(FlSpot(2, s.ebayOpen!));
    if (s.ebaySealed != null) spots.add(FlSpot(3, s.ebaySealed!));

    final vals = spots.map((e) => e.y).toList();
    final minY = (vals.reduce((a, b) => a < b ? a : b) * .9).floorToDouble();
    final maxY = (vals.reduce((a, b) => a > b ? a : b) * 1.1).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(children: [
        Expanded(
          child: LineChart(LineChartData(
            minY: minY, maxY: maxY,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = ['MSRP', 'Paid', 'Open', 'Sealed'];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Text(labels[i],
                      style: BT.mono(size: 8, color: bt.tx3));
                },
              )),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: BT.yellow3,
                barWidth: 3,
                dotData: FlDotData(
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: BT.yellow,
                    strokeColor: BT.ink,
                    strokeWidth: BT.bw,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: BT.yellow.withOpacity(.1),
                ),
              ),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 8, children: [
          if (s.retail     != null)
            _legend(BT.yellow3, 'MSRP \$${s.retail!.toStringAsFixed(0)}',
                bt),
          if (s.paid       != null)
            _legend(bt.tx,    'Paid \$${s.paid!.toStringAsFixed(0)}', bt),
          if (s.ebayOpen   != null)
            _legend(BT.green, 'Open \$${s.ebayOpen!.toStringAsFixed(0)}',
                bt),
          if (s.ebaySealed != null)
            _legend(BT.blue,
                'Sealed \$${s.ebaySealed!.toStringAsFixed(0)}', bt),
        ]),
      ]),
    );
  }

  Widget _legend(Color color, String label, BrikStaxColors bt) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 14, height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: BT.mono(size: 9, color: bt.tx2)),
      ]);
}

// ── Details tab ───────────────────────────────────────────────────────────────
class _DetailsTab extends StatefulWidget {
  final LegoSet s;
  const _DetailsTab({required this.s});
  @override State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  late final TextEditingController _notes;
  @override void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.s.notes);
  }
  @override void dispose() { _notes.dispose(); super.dispose(); }

  void _save(LegoSet updated) {
    context.read<CollectionProvider>().update(updated);
  }

  // ── Edit: Condition (sealed/open) — tapping toggles + prompts extras ───────
  Future<void> _editCondition(LegoSet s) async {
    final newStatus = s.status == 'sealed' ? 'open' : 'sealed';
    if (newStatus == 'open') {
      final extras = await OpenExtrasSheet.show(context, s.openExtras);
      if (extras != null && mounted) {
        _save(s.copyWith(status: 'open', openExtras: extras));
      }
    } else {
      _save(s.copyWith(status: 'sealed', openExtras: const OpenExtras()));
    }
  }

  // ── Edit: Extras (box/manual) — only shown when open ───────────────────────
  Future<void> _editExtras(LegoSet s) async {
    final extras = await OpenExtrasSheet.show(context, s.openExtras);
    if (extras != null && mounted) {
      _save(s.copyWith(openExtras: extras));
    }
  }

  // ── Edit: Qty owned ─────────────────────────────────────────────────────
  Future<void> _editQty(LegoSet s) async {
    final ctrl = TextEditingController(text: s.qty.toString());
    final bt = context.bt;
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Text('Quantity owned', style: BT.display(size: 22, color: bt.tx)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: BT.mono(size: 16, color: bt.tx),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final n = int.tryParse(ctrl.text.trim());
                Navigator.pop(ctx, (n != null && n > 0) ? n : null);
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );
    if (result != null) _save(s.copyWith(qty: result));
  }

  // ── Edit: Retail / Paid — shared price-field sheet ─────────────────────────
  Future<void> _editPrice(LegoSet s, {required bool isRetail}) async {
    final current = isRetail ? s.retail : s.paid;
    final ctrl = TextEditingController(
        text: current != null ? current.toStringAsFixed(2) : '');
    final bt = context.bt;
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20, right: 20, top: 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Text(isRetail ? 'MSRP / Retail price' : 'Price paid',
                style: BT.display(size: 22, color: bt.tx)),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: BT.mono(size: 16, color: bt.tx),
                decoration: InputDecoration(
                  prefixText: '\$',
                  prefixStyle: BT.mono(size: 16, color: bt.txMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final v = double.tryParse(
                    ctrl.text.trim().replaceAll(',', ''));
                Navigator.pop(ctx, v);
              },
              child: const Text('Save'),
            ),
          ]),
        ),
      ),
    );
    if (result != null) {
      _save(isRetail ? s.copyWith(retail: result) : s.copyWith(paid: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final s  = widget.s;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
      children: [
        _card(bt, [
          InfoRow(label: 'Set number', value: s.num),
          InfoRow(label: 'Year',       value: s.year?.toString() ?? '—'),
          InfoRow(label: 'Pieces',     value: s.pieces?.toString() ?? '—'),
          InfoRow(label: 'Theme',
              value: s.theme?.split(' > ').first ?? '—'),
          InfoRow(label: 'Subtheme',   value: s.subtheme ?? '—'),
        ]),
        const SizedBox(height: 12),

        // ── Editable rows ────────────────────────────────────────────────
        Text('TAP TO EDIT', style: BT.mono(size: 9, color: bt.tx3)),
        const SizedBox(height: 6),
        _editableCard(bt, [
          _editRow(bt,
            label: 'Condition',
            value: s.status == 'sealed' ? '📦 Sealed' : '🔓 Open',
            onTap: () => _editCondition(s),
          ),
          if (s.status == 'open')
            _editRow(bt,
              label: 'Extras',
              value: s.openExtras.label,
              onTap: () => _editExtras(s),
            ),
          _editRow(bt,
            label: 'Qty owned',
            value: s.qty.toString(),
            onTap: () => _editQty(s),
          ),
          _editRow(bt,
            label: 'MSRP / Retail',
            value: s.retail != null
                ? '\$${s.retail!.toStringAsFixed(2)}' : 'Not set',
            onTap: () => _editPrice(s, isRetail: true),
          ),
          _editRow(bt,
            label: 'Price paid',
            value: s.paid != null
                ? '\$${s.paid!.toStringAsFixed(2)}' : 'Not set',
            onTap: () => _editPrice(s, isRetail: false),
            isLast: true,
          ),
        ]),
        const SizedBox(height: 12),

        // Purchase source
        GestureDetector(
          onTap: () async {
            final r =
                await PurchaseSourceSheet.show(context, s.purchaseSource);
            if (r != null && mounted) {
              context.read<CollectionProvider>()
                  .update(s.copyWith(purchaseSource: r));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: s.purchaseSource.earnsInsiderPoints
                  ? BT.yellowBg : bt.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: s.purchaseSource.earnsInsiderPoints
                    ? BT.yellow3 : bt.cardBorder,
                width: BT.bw,
              ),
              boxShadow: [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
            ),
            child: Row(children: [
              Text(s.purchaseSource.emoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.purchaseSource.label, style: BT.body(size: 14, color: bt.tx)),
                if (s.purchaseSource.earnsInsiderPoints &&
                    (s.insiderPoints ?? 0) > 0)
                  Text(
                      '\$${s.insiderPoints!.toStringAsFixed(2)} Insider points',
                      style: BT.mono(size: 9, color: BT.gold)),
              ])),
              Icon(Icons.chevron_right, color: bt.txMuted, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Notes
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notes', style: BT.mono(size: 9, color: bt.tx3)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
            ),
            child: TextField(
              controller: _notes,
              maxLines: 3,
              style: BT.mono(size: 13, color: bt.tx),
              decoration: InputDecoration(
                hintText: 'Add notes…',
                hintStyle: BT.mono(size: 13, color: bt.txMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: BT.yellow3, width: BT.bw),
                ),
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (v) => context
                  .read<CollectionProvider>()
                  .update(s.copyWith(notes: v)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _card(BrikStaxColors bt, List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
      boxShadow: [BoxShadow(color: bt.shadowColor,
          offset: const Offset(2, 2))],
    ),
    child: Column(children: rows),
  );

  Widget _editableCard(BrikStaxColors bt, List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
      boxShadow: [BoxShadow(color: bt.shadowColor,
          offset: const Offset(2, 2))],
    ),
    child: Column(children: rows),
  );

  Widget _editRow(
    BrikStaxColors bt, {
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(
                    color: bt.surface2, width: 1)),
          ),
          child: Row(children: [
            Text(label, style: BT.mono(size: 11, color: bt.tx3)),
            const Spacer(),
            Text(value, style: BT.body(size: 14, color: bt.tx)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: bt.txMuted, size: 16),
          ]),
        ),
      );
}
