// lib/modules/avatar/widgets/daily_five_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/lego_set.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';
import '../../../utils/ebay_affiliate.dart';
import '../data/daily_content.dart';
import '../services/daily_five_service.dart';
import 'daily_claim_screen.dart';
import 'loot_roll_widget.dart';

class DailyFiveScreen extends StatefulWidget {
  const DailyFiveScreen({super.key});
  @override State<DailyFiveScreen> createState() => _State();
}

class _State extends State<DailyFiveScreen> {
  @override
  void initState() {
    super.initState();
    DailyFiveService.instance.ensureToday();
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final bt   = context.bt;
    final svc  = DailyFiveService.instance;
    final done = svc.completedCount;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        // Header
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: bt.cardBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: bt.cardBorder, width: BT.bw),
                      boxShadow: [BoxShadow(
                          color: bt.shadowColor,
                          offset: const Offset(2, 2))],
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: bt.tx, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Daily 5', style: BT.display(size: 26, color: bt.tx)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: done == 5 ? BT.yellow : BT.ink,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: BT.ink, width: BT.bw),
                  ),
                  child: Text('$done / 5',
                      style: BT.display(size: 15,
                          color: done == 5 ? BT.ink : BT.yellow)),
                ),
              ]),
            ),
          ),
        ),

        Expanded(child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _taskCard(bt,
              task: DailyTask.checkin,
              emoji: '🧱', title: 'Daily Check-in',
              subtitle: 'Claim your daily brick',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const DailyClaimScreen()));
                _refresh();
              },
            ),
            _taskCard(bt,
              task: DailyTask.portfolio,
              emoji: '📈', title: 'Portfolio Pulse',
              subtitle: 'Check today\'s market value',
              onTap: () => _showPortfolio(bt),
            ),
            _taskCard(bt,
              task: DailyTask.tip,
              emoji: '💡', title: 'Tip of the Day',
              subtitle: 'A collector secret',
              onTap: () => _showTip(bt),
            ),
            _taskCard(bt,
              task: DailyTask.trivia,
              emoji: '🧠', title: 'Trivia Quiz',
              subtitle: 'Test your brick knowledge',
              onTap: () => _showTrivia(bt),
            ),
            _taskCard(bt,
              task: DailyTask.spotlight,
              emoji: '🔦', title: 'Collection Spotlight',
              subtitle: 'Revisit a set you own',
              onTap: () => _showSpotlight(bt),
            ),

            const SizedBox(height: 8),
            if (svc.bonusAvailable) _bonusCard(),
            if (svc.allComplete && !svc.bonusAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: Text(
                    '🎉 All done today — see you tomorrow!',
                    style: BT.mono(size: 11, color: bt.tx2))),
              ),
          ],
        )),
      ]),
    );
  }

  Widget _taskCard(
    BrikStaxColors bt, {
    required DailyTask task,
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final done = DailyFiveService.instance.isDone(task);
    return GestureDetector(
      onTap: done && task != DailyTask.checkin ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? bt.surface2 : bt.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done
                  ? const Color(0xFF1D9E75) : bt.cardBorder,
              width: BT.bw),
          boxShadow: done
              ? []
              : [BoxShadow(color: bt.shadowColor,
                  offset: const Offset(2, 2))],
        ),
        child: Row(children: [
          Opacity(
            opacity: done ? 0.5 : 1.0,
            child: Text(emoji,
                style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: BT.body(size: 15,
                      color: done ? bt.txMuted : bt.tx)),
              Text(subtitle,
                  style: BT.mono(size: 9, color: bt.tx3)),
            ],
          )),
          if (done)
            const Icon(Icons.check_circle,
                color: Color(0xFF1D9E75), size: 24)
          else
            Icon(Icons.chevron_right, color: bt.txMuted, size: 22),
        ]),
      ),
    );
  }

  Widget _bonusCard() => GestureDetector(
    onTap: () async {
      final result = await DailyFiveService.instance.claimBonus();
      if (result != null && mounted) {
        await LootRollWidget.show(context, result.roll);
      }
      _refresh();
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BT.yellow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BT.ink, width: BT.bw),
        boxShadow: BT.shadow,
      ),
      child: Row(children: [
        const Text('🎁', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily 5 complete!', style: BT.display(size: 16, color: BT.ink)),
            Text('Tap to claim your bonus roll',
                style: BT.mono(size: 10, color: BT.tx2)),
          ],
        )),
        const Icon(Icons.chevron_right, color: BT.ink, size: 22),
      ]),
    ),
  );

  // ── Task: Portfolio ────────────────────────────────────────────────────
  Future<void> _showPortfolio(BrikStaxColors bt) async {
    final col = context.read<CollectionProvider>();
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: bt.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bt.cardBorder, width: BT.bw),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📈 Portfolio Pulse', style: BT.display(size: 18, color: bt.tx)),
            const SizedBox(height: 12),
            if (col.count == 0)
              Text(
                  'Add some sets first, then your portfolio value will show '
                  'here each day.',
                  style: BT.body(size: 14, color: bt.tx))
            else ...[
              _statRow(bt, 'Sets tracked', '${col.count}'),
              _statRow(bt, 'Market value',
                  '\$${col.totalMarket.toStringAsFixed(0)}'),
              if (col.portfolioRoi != null)
                _statRow(bt, 'Overall ROI',
                    '${col.portfolioRoi! >= 0 ? "+" : ""}${col.portfolioRoi!.toStringAsFixed(1)}%',
                    color: col.portfolioRoi! >= 0
                        ? BT.green : const Color(0xFFE24B4A)),
              if (col.topGainers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Top gainer: ${col.topGainers.first.name.isNotEmpty ? col.topGainers.first.name : "Set ${col.topGainers.first.num}"}',
                  style: BT.mono(size: 10, color: bt.tx3),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openEbaySell(col.topGainers.first),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: BT.greenBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BT.green, width: BT.bw),
                    ),
                    child: Row(children: [
                      const Text('💰', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("It's climbing — see what it's selling for",
                            style: BT.body(size: 12, color: BT.green,
                                weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text('via eBay', style: BT.mono(size: 8, color: bt.tx3)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: BT.yellowBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: BT.gold, width: 1),
                            ),
                            child: Text('AFFILIATE',
                                style: BT.mono(size: 6, color: BT.gold)),
                          ),
                        ]),
                      ])),
                      const Icon(Icons.open_in_new, size: 14, color: BT.green),
                    ]),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: Center(child: Text('Nice!',
                    style: BT.body(size: 14, color: BT.ink))),
              ),
            ),
          ]),
        ),
      ),
    );
    await DailyFiveService.instance.markDone(DailyTask.portfolio);
    _refresh();
  }

  Future<void> _openEbaySell(LegoSet set) async {
    final url = ebayAffiliateSoldSearchUrl(
      setNum: set.num,
      setName: set.name,
      source: 'portfolio_pulse',
    );
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _statRow(BrikStaxColors bt, String label, String value, {Color? color}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: BT.mono(size: 11, color: bt.tx3)),
          Text(value, style: BT.body(size: 14, color: color ?? bt.tx)),
        ]),
      );

  // ── Task: Tip ─────────────────────────────────────────────────────────
  Future<void> _showTip(BrikStaxColors bt) async {
    final tip = DailyContent.todayTip();
    await showDialog(
      context: context,
      builder: (_) => _infoDialog(bt, '💡 Tip of the Day', tip),
    );
    await DailyFiveService.instance.markDone(DailyTask.tip);
    _refresh();
  }

  // ── Task: Trivia ──────────────────────────────────────────────────────
  Future<void> _showTrivia(BrikStaxColors bt) async {
    final q = DailyContent.todayTrivia();
    int? picked;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) =>
          StatefulBuilder(builder: (dCtx, setD) {
        return Dialog(
          backgroundColor: bt.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: bt.cardBorder, width: BT.bw),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('🧠 Trivia Quiz',
                  style: BT.display(size: 18, color: bt.tx)),
              const SizedBox(height: 10),
              Text(q.question, style: BT.body(size: 14, color: bt.tx)),
              const SizedBox(height: 12),
              ...List.generate(q.options.length, (i) {
                final answered = picked != null;
                final correct  = i == q.answerIndex;
                Color bg = bt.cardBg;
                Color bd = bt.cardBorder;
                if (answered) {
                  if (correct) {
                    bg = const Color(0xFFE1F5EE);
                    bd = const Color(0xFF1D9E75);
                  } else if (i == picked) {
                    bg = const Color(0xFFFCEBEB);
                    bd = const Color(0xFFE24B4A);
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: answered
                        ? null
                        : () => setD(() => picked = i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: bd, width: BT.bw),
                      ),
                      child: Text(q.options[i],
                          style: BT.body(size: 13, color: bt.tx)),
                    ),
                  ),
                );
              }),
              if (picked != null) ...[
                const SizedBox(height: 4),
                Text(
                  picked == q.answerIndex
                      ? '✓ Correct!'
                      : '✗ Not quite',
                  style: BT.body(size: 13,
                      color: picked == q.answerIndex
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFFE24B4A)),
                ),
                const SizedBox(height: 4),
                Text(q.fact,
                    style: BT.mono(size: 10, color: bt.tx2)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(dCtx),
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: BT.ink, width: BT.bw),
                    ),
                    child: Center(child: Text('Done',
                        style: BT.body(size: 14,
                            color: BT.ink))),
                  ),
                ),
              ],
            ]),
          ),
        );
      }),
    );
    await DailyFiveService.instance.markDone(DailyTask.trivia);
    _refresh();
  }

  // ── Task: Spotlight ───────────────────────────────────────────────────
  Future<void> _showSpotlight(BrikStaxColors bt) async {
    final col = context.read<CollectionProvider>();
    if (col.sets.isEmpty) {
      await showDialog(
          context: context,
          builder: (_) => _infoDialog(bt, '🔦 Collection Spotlight',
              'Add some sets first, then a random one from your '
              'collection will shine here each day.'));
      await DailyFiveService.instance.markDone(DailyTask.spotlight);
      _refresh();
      return;
    }
    final now  = DateTime.now();
    final seed = now.year * 1000 + now.month * 50 + now.day;
    final s    = col.sets[Random(seed).nextInt(col.sets.length)];

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: bt.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bt.cardBorder, width: BT.bw),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('🔦 Spotlight', style: BT.display(size: 18, color: bt.tx)),
            const SizedBox(height: 12),
            if (s.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(s.imageUrl!, height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink()),
              ),
            const SizedBox(height: 10),
            Text(
              s.name?.isNotEmpty == true ? s.name! : 'Set ${s.num}',
              style: BT.display(size: 16, color: bt.tx),
            ),
            const SizedBox(height: 4),
            Text(
              '#${s.num}${s.theme != null ? " · ${s.theme}" : ""}',
              style: BT.mono(size: 10, color: bt.tx3),
            ),
            if (s.ebayAvg != null) ...[
              const SizedBox(height: 8),
              Text(
                'Market: \$${(s.ebayAvg as num).toStringAsFixed(0)}',
                style: BT.body(size: 14, color: BT.green),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: Center(child: Text('Nice!',
                    style: BT.body(size: 14, color: BT.ink))),
              ),
            ),
          ]),
        ),
      ),
    );
    await DailyFiveService.instance.markDone(DailyTask.spotlight);
    _refresh();
  }

  Widget _infoDialog(BrikStaxColors bt, String title, String body) =>
      Dialog(
        backgroundColor: bt.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bt.cardBorder, width: BT.bw),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: BT.display(size: 18, color: bt.tx)),
            const SizedBox(height: 10),
            Text(body, style: BT.body(size: 14, color: bt.tx)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: BT.yellow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BT.ink, width: BT.bw),
                ),
                child: Center(child: Text('Got it',
                    style: BT.body(size: 14, color: BT.ink))),
              ),
            ),
          ]),
        ),
      );
}
