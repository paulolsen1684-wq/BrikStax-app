// lib/screens/dashboard.dart — BrikStax Brick UI
//
// Grouped into three labeled sections (Today / Your Collection / Discover)
// instead of a flat stack of equally-weighted cards, with the header's ROI
// badge and the old separate "Portfolio" card merged into one hero Market
// Value block -- one opening statement instead of the same number showing
// up in three separate places on scroll. Every color here comes from
// context.bt (per-theme) except the fixed green/red gain-loss semantics,
// so this redraws correctly across light/dark and all of BrikTheme, not
// just the default Classic palette.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lego_set.dart';
import '../modules/avatar/avatar_module.dart';
import '../providers/collection.dart';
import '../services/news.dart';
import '../theme/app_theme.dart';
import '../theme/app_themes.dart';
import '../widgets/atoms.dart';
import '../widgets/set_card.dart';
import 'set_detail.dart';
import 'add_set.dart';
import '../modules/avatar/widgets/near_miss_card.dart';
import '../modules/avatar/widgets/daily_five_screen.dart';
import '../modules/avatar/widgets/hidden_themes_screen.dart';
import '../modules/avatar/widgets/deal_of_day_card.dart';
import '../modules/avatar/widgets/wishlist_dashboard_card.dart';
import '../modules/avatar/widgets/set_lookup_card.dart';
import '../modules/avatar/widgets/parts_checker_card.dart';
import '../modules/avatar/data/backgrounds_art.dart' as bgArt;
import 'collection_share_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Consumer<CollectionProvider>(
      builder: (_, col, __) {
        if (col.loading) return const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(BT.yellow)));

        final insider = col.totalInsider;

        return CustomScrollView(slivers: [

          // ── Hero — wordmark + one consolidated Market Value statement ────
          SliverToBoxAdapter(child: _Hero(col: col)),

          // ── Minifig — moved up from the bottom of the scroll (was buried
          //    after the news feed, a cramped 60px thumbnail) so the avatar
          //    actually reads as a core piece of the app's identity instead
          //    of something most users would never scroll far enough to
          //    see. Right after the Hero: money identity, then character
          //    identity, then the task list starts. No SectionHeader above
          //    it -- the card carries its own "My Minifig" heading and Den
          //    link now, so a redundant outer title/action row was dropped.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: _AvatarSection(),
            ),
          ),

          // ── Near-miss prompt (kept top-level: time-sensitive, not just
          //    another item in a section) ────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
              child: NearMissCard(),
            ),
          ),

          // ── TODAY ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: SectionHeader(title: 'Today')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: DailyBrickClaimCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(children: [
                Expanded(child: _TodayMiniCard(
                  icon: Icons.event_note_outlined,
                  title: 'Daily 5',
                  subtitle: 'Check in & earn',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const DailyFiveScreen())),
                )),
                const SizedBox(width: 10),
                Expanded(child: _TodayMiniCard(
                  icon: Icons.explore_outlined,
                  title: 'Hidden Themes',
                  subtitle: 'Discover challenges',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HiddenThemesScreen())),
                )),
              ]),
            ),
          ),

          // ── YOUR COLLECTION ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SectionHeader(title: 'Your Collection'),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                border: Border(
                  bottom: BorderSide(color: bt.cardBorder, width: BT.bw),
                ),
              ),
              child: Row(children: [
                _Stat(col.count.toString(), 'Sets'),
                _Stat(col.sealedCount.toString(), 'Sealed'),
                _Stat(
                  insider > 0 ? '\$${insider.toStringAsFixed(0)}' : '—',
                  'Insider',
                  color: BT.gold,
                ),
              ]),
            ),
          ),

          if (col.byTheme.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bt.cardBorder, width: BT.bw),
                    boxShadow: [BoxShadow(
                        color: bt.shadowColor.withOpacity(.5),
                        offset: const Offset(2, 2))],
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Text('Collection by theme',
                          style: BT.mono(size: 9, color: bt.tx3)),
                    ),
                    Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: bt.cardBorder, width: BT.bw),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        children: col.byTheme.entries.map((e) {
                          final pct = e.value / col.count;
                          return Expanded(
                            flex: (pct * 100).round().clamp(1, 100),
                            child: Container(color: themeColor(e.key)),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Wrap(
                        spacing: 10, runSpacing: 6,
                        children: col.byTheme.entries.take(6).map((e) =>
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: themeColor(e.key),
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                    color: bt.cardBorder, width: 1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.key.split(' > ').first} (${e.value})',
                              style: BT.mono(size: 9, color: bt.tx2),
                            ),
                          ]),
                        ).toList(),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

          // ── DISCOVER ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SectionHeader(title: 'Discover'),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: DealOfDayCard(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: WishlistDashboardCard(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SetLookupCard(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: PartsCheckerCard(),
            ),
          ),
          const SliverToBoxAdapter(child: _NewsFeed()),

          // ── Top gainers ──────────────────────────────────────────────────
          if (col.topGainers.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SectionHeader(
                  title: '🔥 Top Gainers',
                  action: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = col.topGainers[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SetDetailScreen(setId: s.id))),
                      child: SetCard(set: s),
                    ),
                  );
                },
                childCount: col.topGainers.length,
              ),
            ),
          ],

          // ── Retirement price-climb window ──────────────────────────────
          if (col.inRetirementWindow.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SectionHeader(
                  title: '⏳ Price Climb Window',
                  action: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s = col.inRetirementWindow[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SetDetailScreen(setId: s.id))),
                      child: SetCard(set: s),
                    ),
                  );
                },
                childCount: col.inRetirementWindow.length,
              ),
            ),
          ],

          // ── Empty state ──────────────────────────────────────────────────
          if (col.count == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const AddSetScreen())),
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: bt.primary.withOpacity(.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: bt.cardBorder, width: BT.bw),
                          boxShadow: [BoxShadow(
                              color: bt.shadowColor,
                              offset: const Offset(3, 3))],
                        ),
                        child: Icon(Icons.add, size: 40, color: bt.tx),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Start your collection',
                        style: BT.display(size: 28, color: bt.tx)),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first LEGO set using the + button',
                      style: BT.mono(size: 12, color: bt.tx2),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ]);
      },
    );
  }

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────
// Wordmark + tagline + (if there's market data) one Market Value statement:
// big number, a gain/loss delta pill, and the sparkline. This replaces three
// things the old layout showed separately on scroll: the header's own ROI
// badge, the mid-scroll "Market Value" card, and that card's sparkline.
//
// Text sits on bt.headerBg, which is a saturated theme color for several
// unlockable themes (e.g. City's blue, Botanical's green) rather than a
// neutral surface -- bt.tx is used for the big number instead of the old
// card's fixed BT.green, since fixed green text would go low-contrast (or
// disappear entirely) against Botanical's green header. The delta pill and
// sparkline get their own solid bt.cardBg backing for the same reason: a
// thin green line or green-tinted pill directly on a green header isn't
// guaranteed to read, but bt.cardBg is guaranteed distinct from bt.headerBg
// in every theme (that contrast is the whole basis of the card system).
class _Hero extends StatelessWidget {
  final CollectionProvider col;
  const _Hero({required this.col});

  @override
  Widget build(BuildContext context) {
    final bt     = context.bt;
    final market = col.totalMarket;
    final paid   = col.totalPaid;
    final gain   = market - paid;
    final roi    = paid > 0 ? (gain / paid * 100) : null;
    final up     = gain >= 0;

    // Photo-forward hero: uses the equipped Den's real generated photo
    // (bgArt.denImageAsset) as the backdrop when one exists (48 of 52
    // background ids do) instead of the flat StudBackground fill, so the
    // very first thing on the screen reflects what the user actually built
    // in their Den. Reads AchievementService directly (ListenableBuilder,
    // same pattern as MinifigPreviewCard) since _Hero previously only
    // depended on CollectionProvider and had no reason to rebuild when the
    // avatar's background changes.
    return ListenableBuilder(
      listenable: AchievementService.instance,
      builder: (_, __) {
        final bgId = AchievementService.instance.state.backgroundId;
        final imageAsset = bgArt.denImageAsset(bgId);
        final content = _content(bt, market, paid, gain, roi, up,
            useWhiteText: imageAsset != null);

        if (imageAsset == null) {
          // One of the 4 procedural-only ids (no real Den photo yet) --
          // unchanged flat studded treatment, theme-token text.
          return StudBackground(
            color: bt.headerBg,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                    color: bt.headerBorder, width: BT.bw)),
              ),
              child: content,
            ),
          );
        }

        // Dark gradient scrim over the photo guarantees the (fixed white)
        // text stays legible regardless of which of the 48 photos is
        // equipped -- a brightness check against one palette color
        // wouldn't reliably predict legibility against a busy image the
        // way it does against a flat fill, so this sidesteps that instead
        // of trying to compute it per photo.
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: bt.headerBorder, width: BT.bw)),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(.35),
                      Colors.black.withOpacity(.72),
                    ],
                  ),
                ),
              ),
            ),
            content,
          ]),
        );
      },
    );
  }

  Widget _content(BrikStaxColors bt, double market, double paid, double gain,
      double? roi, bool up, {required bool useWhiteText}) {
    final txColor  = useWhiteText ? Colors.white : bt.tx;
    final tx3Color = useWhiteText ? Colors.white70 : bt.tx3;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('BrikStax', style: BT.display(size: 28, color: txColor)),
              Text(
                '${col.count} set${col.count != 1 ? "s" : ""}  ·  '
                'track every brick',
                style: BT.mono(size: 10, color: tx3Color),
              ),
            ])),
            _HeroShareButton(useWhiteText: useWhiteText),
          ]),

          if (market > 0) ...[
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('MARKET VALUE',
                      style: BT.mono(size: 9, color: tx3Color,
                          weight: FontWeight.w500)),
                  Text('\$${DashboardScreen._fmt(market)}',
                      style: BT.display(size: 36, color: txColor)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: up ? BT.green : BT.red, width: 1.3),
                    ),
                    child: Text(
                      '${up ? "▲" : "▼"} \$${DashboardScreen._fmt(gain.abs())}'
                      '${roi != null ? "  ·  ${up ? "+" : ""}${roi.toStringAsFixed(1)}%" : ""}',
                      style: BT.mono(size: 10.5,
                          color: up ? BT.green : BT.red,
                          weight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                width: 96, height: 46,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: bt.cardBg.withOpacity(.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _Sparkline(col: col),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── Hero share button ─────────────────────────────────────────────────────────
// Was buried in Settings > Tools before this -- wrong precedent to follow
// (that's where Parts Merger lives, a low-frequency utility someone
// deliberately goes looking for). A share card's whole value comes from
// being reached for in the moment, right where its data is shown -- same
// reasoning already applied to Set (share icon on set_detail's own hero)
// and Den (share icon on the Den screen itself). This makes Collection
// consistent with both instead of the one outlier.
class _HeroShareButton extends StatelessWidget {
  final bool useWhiteText;
  const _HeroShareButton({required this.useWhiteText});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CollectionShareScreen())),
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: useWhiteText ? Colors.black.withOpacity(.3) : BT.yellow,
        shape: BoxShape.circle,
        border: useWhiteText ? null : Border.all(color: BT.ink, width: BT.bw),
      ),
      child: Icon(Icons.ios_share, size: 17,
          color: useWhiteText ? Colors.white : BT.ink),
    ),
  );
}

// ── Today mini card ────────────────────────────────────────────────────────────
// Same tile shape the old _MiniNavCard used, but takes a real Icon instead
// of an emoji glyph -- emoji render in their own fixed embedded colors
// regardless of any TextStyle.color set on them, so the calendar/map emoji
// this replaced couldn't actually be recolored to sit quietly on bt.tx the
// way everything else here does; a Material icon can.
class _TodayMiniCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _TodayMiniCard({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: 1.5),
          boxShadow: [BoxShadow(
              color: bt.shadowColor.withOpacity(.5), offset: const Offset(2, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 19, color: bt.tx),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: BT.display(size: 14, color: bt.tx),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(subtitle, style: BT.mono(size: 8, color: bt.tx3),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Stat tile ─────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat(this.value, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(
              color: bt.cardBorder, width: BT.bw)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: BT.display(size: 18, color: color ?? bt.tx)),
          Text(label, style: BT.mono(size: 8, color: bt.tx3)),
        ]),
      ),
    );
  }
}

// ── Sparkline ─────────────────────────────────────────────────────────────────
class _Sparkline extends StatelessWidget {
  final CollectionProvider col;
  const _Sparkline({required this.col});

  @override
  Widget build(BuildContext context) {
    final pts = col.sets
        .map((s) => s.ebayAvg ?? s.retail ?? s.paid ?? 0)
        .where((v) => v > 0)
        .toList();
    if (pts.length < 2) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SparkPainter(pts),
      child: const SizedBox.expand(),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> pts;
  const _SparkPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final minV = pts.reduce((a, b) => a < b ? a : b);
    final maxV = pts.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();
    if (range == 0) return;

    double x(int i) => i / (pts.length - 1) * size.width;
    double y(double v) =>
        size.height - ((v - minV) / range) * (size.height * .8) -
        size.height * .1;

    final path = Path()..moveTo(x(0), y(pts[0]));
    for (int i = 1; i < pts.length; i++) path.lineTo(x(i), y(pts[i]));

    canvas.drawPath(path, Paint()
      ..color = BT.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round);

    final areaPath = Path()..moveTo(x(0), size.height);
    for (int i = 0; i < pts.length; i++) areaPath.lineTo(x(i), y(pts[i]));
    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    canvas.drawPath(areaPath, Paint()
      ..color = BT.green.withOpacity(.12)
      ..style = PaintingStyle.fill);

    canvas.drawCircle(Offset(x(pts.length - 1), y(pts.last)), 3,
        Paint()..color = BT.green..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.pts != pts;
}

// ── News Feed ─────────────────────────────────────────────────────────────────
class _NewsFeed extends StatefulWidget {
  const _NewsFeed();
  @override State<_NewsFeed> createState() => _NewsFeedState();
}

class _NewsFeedState extends State<_NewsFeed> {
  List<NewsItem> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await NewsService.instance.fetch();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    if (_loading) return const Padding(
      padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: SizedBox(height: 80, child: Center(
        child: CircularProgressIndicator(strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(BT.yellow)))),
    );
    if (_items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('LEGO News', style: BT.display(size: 22, color: bt.tx)),
          const Spacer(),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bt.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Text('Refresh',
                  style: BT.mono(size: 9, color: bt.tx2)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          // A 2-line title (common for longer headlines) plus the header
          // row, footer, and Padding/SizedBox spacing in _NewsCard._body
          // add up to ~9px more than this box allowed, overflowing the
          // Column regardless of the summary text's Expanded/Spacer
          // shrinking to fit -- 185 was simply too tight a budget.
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _NewsCard(item: _items[i]),
          ),
        ),
      ]),
    );
  }
}

// ── News card ─────────────────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final NewsItem item;
  const _NewsCard({required this.item});

  bool get _hasImage   => item.imageUrl != null && item.imageUrl!.isNotEmpty;
  bool get _hasUrl     => item.url != null && item.url!.isNotEmpty;
  bool get _hasSummary =>
      item.summary != null && item.summary!.trim().isNotEmpty;

  Future<void> _openUrl() async {
    if (!_hasUrl) return;
    final uri = Uri.tryParse(item.url!);
    if (uri != null && await canLaunchUrl(uri))
      launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openReader(BuildContext context) {
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
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6,
        minChildSize: 0.4, maxChildSize: 0.9,
        builder: (_, scroll) => SafeArea(
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: bt.surface3,
                    borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                const Text('🧱', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('LEGO NEWS',
                    style: BT.mono(size: 9, color: bt.tx3)),
                const Spacer(),
                Text(item.timeAgo,
                    style: BT.mono(size: 9, color: bt.txMuted)),
              ]),
              const SizedBox(height: 12),
              if (_hasImage) ...[
                ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.network(item.imageUrl!,
                      width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink())),
                const SizedBox(height: 14),
              ],
              Text(item.title,
                  style: BT.display(size: 22, color: bt.tx)),
              const SizedBox(height: 12),
              if (_hasSummary)
                Text(item.summary!,
                    style: BT.body(size: 14, color: bt.tx2)),
              if (_hasUrl) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _openUrl,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: bt.primary,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                          color: bt.cardBorder, width: BT.bw),
                      boxShadow: [BoxShadow(
                          color: bt.shadowColor.withOpacity(.5),
                          offset: const Offset(2, 2))],
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text('Read more',
                          style: BT.body(size: 15, color: bt.tx)),
                      const SizedBox(width: 6),
                      Icon(Icons.open_in_new,
                          size: 15, color: bt.tx),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: () => _openReader(context),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(
              color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: _hasImage ? _withImage(bt) : _textOnly(bt),
      ),
    );
  }

  Widget _withImage(BrikStaxColors bt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(height: 84, width: double.infinity,
        child: Image.network(item.imageUrl!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _accentStrip(bt))),
      Expanded(child: _body(bt)),
    ],
  );

  Widget _textOnly(BrikStaxColors bt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_accentStrip(bt), Expanded(child: _body(bt, big: true))],
  );

  Widget _accentStrip(BrikStaxColors bt) => Container(
    height: 8, width: double.infinity,
    decoration: BoxDecoration(
      color: bt.primary,
      border: Border(bottom: BorderSide(
          color: bt.cardBorder, width: BT.bw)),
    ),
  );

  Widget _body(BrikStaxColors bt, {bool big = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('🧱', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 5),
        Text('LEGO NEWS', style: BT.mono(size: 8, color: bt.tx3)),
        const Spacer(),
        Icon(Icons.chevron_right, size: 14, color: bt.txMuted),
      ]),
      const SizedBox(height: 6),
      Text(item.title,
          style: BT.body(size: big ? 15 : 13, color: bt.tx),
          maxLines: big ? 3 : 2, overflow: TextOverflow.ellipsis),
      if (_hasSummary) ...[
        const SizedBox(height: 5),
        Expanded(child: Text(item.summary!,
            style: BT.mono(size: 10, color: bt.tx2),
            maxLines: big ? 4 : 3,
            overflow: TextOverflow.ellipsis)),
      ] else const Spacer(),
      const SizedBox(height: 4),
      Text('Tap to read', style: BT.mono(size: 9, color: bt.txMuted)),
    ]),
  );
}

// ── Avatar section ────────────────────────────────────────────────────────────
class _AvatarSection extends StatefulWidget {
  const _AvatarSection();
  @override State<_AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<_AvatarSection> {
  @override
  void initState() {
    super.initState();
    AchievementService.instance.addListener(_onAchievementChange);
  }

  @override
  void dispose() {
    AchievementService.instance.removeListener(_onAchievementChange);
    super.dispose();
  }

  void _onAchievementChange() {
    final pending = AchievementService.instance.pendingUnlocks;
    if (pending.isEmpty || !mounted) return;
    final id = pending.first;
    AchievementService.instance.dismissUnlock(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AchievementPopup.show(
          context, id, AchievementService.instance.state);
    });
  }

  @override
  Widget build(BuildContext context) => const MinifigPreviewCard();
}
