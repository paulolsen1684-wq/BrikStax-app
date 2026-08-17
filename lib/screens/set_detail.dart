// lib/screens/set_detail.dart — BrikStax Brick UI
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lego_set.dart';
import '../models/brickset_extras.dart';
import '../providers/collection.dart';
import '../services/api.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/atoms.dart';
import '../widgets/sheets.dart';
import 'parts_checker_screen.dart';
import 'set_share_screen.dart';

class SetDetailScreen extends StatefulWidget {
  final String setId;
  const SetDetailScreen({super.key, required this.setId});
  @override State<SetDetailScreen> createState() => _State();
}

class _State extends State<SetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  // BrickSet-sourced extras (instructions, rating, extra images) --
  // fetched once per screen instance, lazily once we know the set's
  // number, not tied to Provider/CollectionProvider since none of this
  // is local collection data.
  BrickSetExtras? _extras;
  bool _extrasRequested = false;

  @override void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override void dispose()   { _tabs.dispose(); super.dispose(); }

  void _loadExtras(String num) {
    if (_extrasRequested) return;
    _extrasRequested = true;
    Api.instance.fetchSetExtras(num).then((extras) {
      if (mounted) setState(() => _extras = extras);
    });
  }

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
        _loadExtras(s.num);

        return Scaffold(
          backgroundColor: bt.surface,
          body: Column(children: [

            // ── Hero ────────────────────────────────────────────────────────
            // Deliberately NOT a SliverAppBar/FlexibleSpaceBar background
            // anymore -- a horizontally-swiped PageView nested inside
            // flexibleSpace competes with CustomScrollView's own vertical
            // drag recognizer for the same gesture arena and reliably
            // loses (confirmed: images displayed and paged via dots, but
            // swipe-to-change-photo silently did nothing). Pulling the
            // hero out to a fixed-height sibling of the CustomScrollView
            // (not a descendant of its Scrollable at all) removes any
            // possible arena competition entirely -- trades away the old
            // collapse-into-toolbar animation for a fixed-height header,
            // which is also just a simpler, very common detail-screen
            // pattern (Airbnb-listing-style: swipeable photo header, page
            // content scrolls independently below it).
            SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(children: [
                _HeroBg(s: s, tc: tc, extras: _extras),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 12,
                  child: _HeroBackButton(),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 12,
                  child: _HeroShareButton(set: s),
                ),
              ]),
            ),

            Expanded(
              child: CustomScrollView(slivers: [

                // ── Price grid ────────────────────────────────────────────
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

                // ── Retirement window banner ─────────────────────────────
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

                // ── Tab bar ───────────────────────────────────────────────
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
                      _DetailsTab(s: s, extras: _extras),
                    ],
                  ),
                ),
              ]),
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
// Swipeable when BrickSet's additional-images call returned more than just
// the primary product shot (see Api.fetchSetExtras) -- falls back to a
// single static image (the old behavior) when there's nothing extra to
// swipe to, so this never depends on the BrickSet fetch having completed.
class _HeroBg extends StatefulWidget {
  final LegoSet s;
  final Color tc;
  final BrickSetExtras? extras;
  const _HeroBg({required this.s, required this.tc, this.extras});

  @override
  State<_HeroBg> createState() => _HeroBgState();
}

class _HeroBgState extends State<_HeroBg> {
  final _pageCtrl = PageController();
  int _page = 0;

  List<String> get _images {
    final list = <String>[];
    if (widget.s.imageUrl != null) list.add(widget.s.imageUrl!);
    for (final u in widget.extras?.additionalImages ?? const <String>[]) {
      if (!list.contains(u)) list.add(u);
    }
    return list;
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final tc = widget.tc;
    final extras = widget.extras;
    final images = _images;

    return Stack(fit: StackFit.expand, children: [
        StudBackground(color: tc, child: const SizedBox.expand()),
        if (images.isNotEmpty)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(.25), BlendMode.darken),
            child: images.length == 1
                ? CachedNetworkImage(
                    imageUrl: images.first,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : PageView.builder(
                    controller: _pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
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
            if (images.length > 1) ...[
              Row(children: List.generate(images.length, (i) =>
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 4),
                  width: i == _page ? 14 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
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
            Row(children: [
              Expanded(child: Text(
                '${s.num}  ·  ${s.year ?? '?'}  ·  '
                '${s.pieces != null ? '${s.pieces} pcs' : ''}',
                style: BT.mono(size: 11, color: Colors.white60),
                overflow: TextOverflow.ellipsis,
              )),
              // BrickSet's average star rating, right next to the set's
              // own name/piece-count line -- per feedback, this belongs up
              // here where it's immediately visible, not buried down in
              // the Details tab (still shown there too, tappable through
              // to the BrickSet page -- this hero copy is display-only).
              if (extras != null && extras.hasRating) ...[
                const SizedBox(width: 8),
                _StarRating(
                  rating: extras.rating!,
                  count: extras.ratingCount,
                  light: true,
                  iconSize: 12,
                ),
              ],
            ]),
          ]),
        ),
      ]);
  }
}

// ── Hero back button ──────────────────────────────────────────────────────────
// A plain floating circular button, standing in for the automatic back
// button SliverAppBar used to provide -- needed now that the hero is a
// fixed Stack sibling rather than a SliverAppBar (see _State.build's hero
// section for why).
class _HeroBackButton extends StatelessWidget {
  const _HeroBackButton();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).maybePop(),
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.35),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
    ),
  );
}

class _HeroShareButton extends StatelessWidget {
  final LegoSet set;
  const _HeroShareButton({required this.set});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => SetShareScreen(set: set))),
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.35),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.ios_share, color: Colors.white, size: 18),
    ),
  );
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
  final BrickSetExtras? extras;
  const _DetailsTab({required this.s, this.extras});
  @override State<_DetailsTab> createState() => _DetailsTabState();
}

class _DetailsTabState extends State<_DetailsTab> {
  late final TextEditingController _notes;
  // User's explicit language pick for the Instructions card, if they've
  // opened the picker -- null means "not chosen yet, default to the first
  // group". Kept separate from a derived/computed value since extras
  // (and therefore the available language groups) can arrive AFTER first
  // build, once the BrickSet fetch resolves -- see SetDetailScreen's
  // _loadExtras.
  String? _selectedLanguage;

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
    final bt     = context.bt;
    final s      = widget.s;
    final extras = widget.extras;

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

        // ── BrickSet community rating ────────────────────────────────────
        if (extras != null && extras.hasRating) ...[
          _ratingCard(bt, extras),
          const SizedBox(height: 12),
        ],

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

        // Check Parts -- only meaningful for a set you've actually opened;
        // a sealed set has no "missing pieces" question to ask yet.
        if (s.status == 'open') ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PartsCheckerScreen(
                    initialNum: s.num, ownedSetName: s.name))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
                boxShadow: [BoxShadow(color: bt.shadowColor,
                    offset: const Offset(2, 2))],
              ),
              child: Row(children: [
                const Text('🧩', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text('Check for missing pieces',
                    style: BT.body(size: 14, color: bt.tx))),
                Icon(Icons.chevron_right, color: bt.txMuted, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],

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

        // ── Instructions (BrickSet) ─────────────────────────────────────
        if (extras != null && extras.hasInstructions) ...[
          Text('Instructions', style: BT.mono(size: 9, color: bt.tx3)),
          const SizedBox(height: 6),
          _instructionsCard(bt, extras),
          const SizedBox(height: 12),
        ],



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

  // ── BrickSet rating card ────────────────────────────────────────────────
  Widget _ratingCard(BrikStaxColors bt, BrickSetExtras extras) => GestureDetector(
    onTap: extras.bricksetUrl != null
        ? () => launchUrl(Uri.parse(extras.bricksetUrl!),
            mode: LaunchMode.externalApplication)
        : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
        boxShadow: [BoxShadow(color: bt.shadowColor,
            offset: const Offset(2, 2))],
      ),
      child: Row(children: [
        Text('BrickSet rating', style: BT.mono(size: 11, color: bt.tx3)),
        const Spacer(),
        _StarRating(rating: extras.rating!, count: extras.ratingCount),
        if (extras.bricksetUrl != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.open_in_new, color: bt.txMuted, size: 14),
        ],
      ]),
    ),
  );

  // ── Instructions card ────────────────────────────────────────────────────
  // Grouped by language (best-effort, parsed from BrickSet's free-text
  // `description` field -- there's no dedicated language field in the API,
  // see _instructionLanguage) with a dropdown-style picker when a set has
  // more than one language available, which is the common case. A set
  // with only one language skips the picker entirely -- nothing to choose.
  Widget _instructionsCard(BrikStaxColors bt, BrickSetExtras extras) {
    final grouped = <String, List<BrickSetInstruction>>{};
    for (int i = 0; i < extras.instructions.length; i++) {
      final lang = _instructionLanguage(extras.instructions[i].description, i);
      grouped.putIfAbsent(lang, () => []).add(extras.instructions[i]);
    }
    // English first when present -- grouped.keys otherwise preserves
    // whatever arbitrary order BrickSet's API returned the entries in,
    // which also silently decided the default `selected` language below.
    final languages = grouped.keys.toList();
    if (languages.remove('English')) languages.insert(0, 'English');
    final selected = (_selectedLanguage != null && grouped.containsKey(_selectedLanguage))
        ? _selectedLanguage!
        : languages.first;
    final items = grouped[selected]!;

    return Container(
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
        boxShadow: [BoxShadow(color: bt.shadowColor,
            offset: const Offset(2, 2))],
      ),
      child: Column(children: [
        if (languages.length > 1) ...[
          _languageDropdown(bt, languages, selected),
          Divider(height: 1, thickness: 1, color: bt.surface2),
        ],
        for (int i = 0; i < items.length; i++)
          _instructionRow(bt, items[i], isLast: i == items.length - 1),
      ]),
    );
  }

  Widget _languageDropdown(
      BrikStaxColors bt, List<String> languages, String selected) =>
      GestureDetector(
        onTap: () async {
          final picked = await _pickLanguage(languages, selected);
          if (picked != null && mounted) {
            setState(() => _selectedLanguage = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            const Icon(Icons.language, size: 16, color: BT.blue),
            const SizedBox(width: 10),
            Text('Language', style: BT.mono(size: 11, color: bt.tx3)),
            const Spacer(),
            Text(selected, style: BT.body(size: 13, color: bt.tx)),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more, color: bt.txMuted, size: 16),
          ]),
        ),
      );

  Future<String?> _pickLanguage(List<String> languages, String current) {
    final bt = context.bt;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bt.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: bt.cardBorder, width: BT.bw),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            Text('Instructions language',
                style: BT.display(size: 22, color: bt.tx)),
            const SizedBox(height: 14),
            for (final lang in languages)
              GestureDetector(
                onTap: () => Navigator.pop(ctx, lang),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: lang == current ? BT.yellowBg : bt.cardBg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: lang == current ? BT.yellow3 : bt.cardBorder,
                      width: BT.bw,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(lang,
                        style: BT.body(size: 14, color: bt.tx))),
                    if (lang == current)
                      const Icon(Icons.check, color: BT.ink, size: 16),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _instructionRow(BrikStaxColors bt, BrickSetInstruction instr,
          {required bool isLast}) =>
      GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse(instr.url), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: bt.surface2, width: 1)),
          ),
          child: Row(children: [
            const Icon(Icons.menu_book_outlined, size: 16, color: BT.blue),
            const SizedBox(width: 10),
            Expanded(child: Text(
                instr.description.isNotEmpty
                    ? instr.description
                    : 'Building instructions',
                style: BT.body(size: 13, color: bt.tx))),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, color: bt.txMuted, size: 15),
          ]),
        ),
      );
}

// ── Language detection for BrickSet instruction entries ────────────────────
// BrickSet's getInstructions2 response has no dedicated language field --
// language (when present at all) is folded into the free-text `description`
// (e.g. "English", "Building Instructions - Deutsch"). Best-effort substring
// match against known language names, falling back to the raw description
// (or a generic numbered label if that's empty too) so grouping never
// crashes or silently drops an entry just because its description doesn't
// look like any of these.
const _kInstructionLanguages = [
  'English', 'French', 'German', 'Dutch', 'Danish', 'Italian', 'Spanish',
  'Portuguese', 'Polish', 'Czech', 'Swedish', 'Norwegian', 'Finnish',
  'Japanese', 'Korean', 'Chinese', 'Russian', 'Hungarian', 'Greek',
  'Turkish', 'Arabic',
  // Native spellings BrickSet sometimes uses instead of the English name
  'Deutsch', 'Français', 'Español', 'Português', 'Italiano', 'Nederlands',
  'Polski', 'Svenska', 'Norsk', 'Suomi', 'Dansk',
];

String _instructionLanguage(String description, int index) {
  final lower = description.toLowerCase();
  for (final lang in _kInstructionLanguages) {
    if (lower.contains(lang.toLowerCase())) return lang;
  }
  final trimmed = description.trim();
  return trimmed.isNotEmpty ? trimmed : 'Instructions ${index + 1}';
}

// ── Star rating (BrickSet average, 0-5) ─────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  final int count;
  // `light` switches to a white/translucent palette for use over a photo
  // (the hero overlay) instead of the default card-on-surface colors used
  // in the Details tab's rating card.
  final bool light;
  final double iconSize;
  const _StarRating({
    required this.rating,
    required this.count,
    this.light = false,
    this.iconSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 0; i < 5; i++)
        Icon(
          rating - i >= 1
              ? Icons.star
              : rating - i >= 0.5
                  ? Icons.star_half
                  : Icons.star_border,
          size: iconSize,
          color: light ? Colors.white : BT.yellow3,
        ),
      const SizedBox(width: 6),
      Text('${rating.toStringAsFixed(1)} ($count)',
          style: BT.mono(size: 10, color: light ? Colors.white70 : bt.tx2)),
    ]);
  }
}
