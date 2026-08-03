// lib/modules/avatar/widgets/daily_claim_screen.dart
import 'package:flutter/material.dart';
import '../models/loot_roll.dart';
import '../services/loot_service.dart';
import 'brik_shop.dart';
import 'loot_roll_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';
import '../../../utils/haptics.dart';

class DailyClaimScreen extends StatefulWidget {
  const DailyClaimScreen({super.key});
  @override State<DailyClaimScreen> createState() => _State();
}

class _State extends State<DailyClaimScreen> {
  bool _claiming = false;

  @override
  Widget build(BuildContext context) {
    final bt     = context.bt;
    final svc    = LootService.instance;
    final streak = svc.streak;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        // Header — always ink/yellow (brand identity for this screen)
        Container(
          decoration: const BoxDecoration(
            color: BT.ink,
            border: Border(
                bottom: BorderSide(color: BT.yellow, width: 3)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: BT.yellow, width: BT.bw),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: BT.ink, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Daily Reward',
                    style: BT.display(size: 26, color: BT.yellow)),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await BrikShop.show(context);
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: BT.yellow, width: BT.bw),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🧱',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text('${svc.briks}',
                          style: BT.display(size: 15, color: bt.tx)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Streak counter — always dark (intentional dramatic card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BT.ink,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BT.yellow, width: 2),
                  boxShadow: const [
                    BoxShadow(color: BT.yellow, offset: Offset(3, 3))
                  ],
                ),
                child: Column(children: [
                  const Text('🔥',
                      style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('${streak.streak}',
                      style: BT.display(size: 64, color: BT.yellow)),
                  Text('day streak',
                      style: BT.mono(size: 12,
                          color: BT.yellow.withOpacity(.7))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: BT.yellow.withOpacity(.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: BT.yellow.withOpacity(.3)),
                    ),
                    child: Text(streak.streakMilestoneLabel,
                        style: BT.mono(size: 10,
                            color: BT.yellow.withOpacity(.8))),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // Today's brick tier
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bt.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                  boxShadow: [BoxShadow(color: bt.shadowColor,
                      offset: const Offset(3, 3))],
                ),
                child: Row(children: [
                  _PixelBrickIcon(tier: streak.nextTier),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's reward",
                          style: BT.mono(size: 9, color: bt.tx3)),
                      Text(streak.tierLabel,
                          style: BT.display(size: 18, color: bt.tx)),
                      const SizedBox(height: 4),
                      Text(_tierDescription(streak.nextTier),
                          style: BT.mono(size: 9, color: bt.tx2)),
                      const SizedBox(height: 2),
                      Text(
                        '+1 🧱 Brik every claim · dupes pay full value',
                        style: BT.mono(size: 8, color: bt.tx3),
                      ),
                    ],
                  )),
                ]),
              ),

              const SizedBox(height: 16),

              _StreakDots(current: streak.streak),

              const SizedBox(height: 20),

              // Claim button
              if (streak.canClaim)
                GestureDetector(
                  onTap: _claiming ? null : _claim,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: BT.ink, width: BT.bw),
                      boxShadow: BT.shadow,
                    ),
                    child: _claiming
                        ? const Center(child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(BT.ink))))
                        : Text('Crack the Brick!',
                            textAlign: TextAlign.center,
                            style: BT.display(size: 20, color: bt.tx)),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: bt.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: bt.cardBorder, width: BT.bw),
                  ),
                  child: Column(children: [
                    Text('Already claimed today!',
                        textAlign: TextAlign.center,
                        style: BT.body(size: 16, color: bt.txMuted)),
                    const SizedBox(height: 4),
                    Text(
                      'Come back tomorrow to keep your streak',
                      textAlign: TextAlign.center,
                      style: BT.mono(size: 10, color: bt.txMuted),
                    ),
                  ]),
                ),

              const SizedBox(height: 12),

              // Brik Shop button
              GestureDetector(
                onTap: () async {
                  await BrikShop.show(context);
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: bt.cardBorder, width: BT.bw),
                    boxShadow: [BoxShadow(color: bt.shadowColor,
                        offset: const Offset(2, 2))],
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Text('🧱',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text('Brik Shop', style: BT.body(size: 15, color: bt.tx)),
                    const SizedBox(width: 8),
                    Text('${svc.briks} Briks',
                        style: BT.mono(size: 10, color: bt.tx3)),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              if (streak.longest > 0)
                Text('Best streak: ${streak.longest} days',
                    style: BT.mono(size: 10, color: bt.tx3)),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _claim() async {
    BrikHaptics.medium();
    setState(() => _claiming = true);
    final result = await LootService.instance.claimDaily();
    setState(() => _claiming = false);
    if (result != null && mounted) {
      BrikHaptics.heavy();
      await LootRollWidget.show(
        context,
        result.roll,
        briksEarned: result.briksEarned,
        wasDupe: result.wasDupe,
      );
      setState(() {});
    }
  }

  String _tierDescription(BrickTier tier) => switch (tier) {
    BrickTier.common => '70% common · 25% rare · 5% epic',
    BrickTier.rare   => '50% rare · 40% epic · 10% legendary',
    BrickTier.epic   => '80% legendary · 20% epic',
  };
}

// ── Streak milestone dots ─────────────────────────────────────────────────────
class _StreakDots extends StatelessWidget {
  final int current;
  const _StreakDots({required this.current});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    const milestones = [1, 3, 7, 14, 30];
    const labels     = ['Day 1', 'Day 3', 'Day 7', 'Day 14', 'Day 30'];
    const tiers      = ['Common', 'Common', 'Rare+', 'Rare', 'Epic+'];
    const colors     = [
      Color(0xFF888888), Color(0xFF888888),
      Color(0xFF006CB7), Color(0xFF006CB7),
      Color(0xFF8B00FF),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
        boxShadow: [BoxShadow(color: bt.shadowColor,
            offset: const Offset(3, 3))],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Streak milestones',
            style: BT.mono(size: 9, color: bt.tx3)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(milestones.length, (i) {
            final reached = current >= milestones[i];
            return Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: reached ? colors[i] : bt.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reached ? colors[i] : bt.cardBorder,
                    width: 2,
                  ),
                ),
                child: Center(child: Text(
                  reached ? '✓' : '🧱',
                  style: const TextStyle(fontSize: 18),
                )),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: BT.mono(size: 8, color: bt.tx3)),
              Text(tiers[i],
                  style: BT.mono(size: 7,
                      color: reached ? colors[i] : bt.txMuted)),
            ]);
          }),
        ),
        const SizedBox(height: 10),
        Text('Day 7: Rare+ · Day 30: Epic+ · Day 100: Legendary',
            style: BT.mono(size: 8, color: bt.tx3)),
      ]),
    );
  }
}

// ── Small pixel brick icon (fixed colors — it's a game element) ───────────────
class _PixelBrickIcon extends StatelessWidget {
  final BrickTier tier;
  const _PixelBrickIcon({required this.tier});

  Color get _color => switch (tier) {
    BrickTier.common => BT.yellow,
    BrickTier.rare   => const Color(0xFF006CB7),
    BrickTier.epic   => const Color(0xFF8B00FF),
  };

  @override
  Widget build(BuildContext context) => Container(
    width: 56, height: 56,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _color.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _color, width: 2),
    ),
    child: CustomPaint(painter: _MiniBrickPainter(color: _color)),
  );
}

class _MiniBrickPainter extends CustomPainter {
  final Color color;
  const _MiniBrickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    p.color = color;
    canvas.drawRect(Rect.fromLTWH(0, h * .3, w, h * .7), p);
    final top = Path()
      ..moveTo(0, h * .3)
      ..lineTo(w * .5, 0)
      ..lineTo(w, h * .3)
      ..lineTo(w * .5, h * .6)
      ..close();
    p.color = HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness + .1).clamp(0.0, 1.0))
        .toColor();
    canvas.drawPath(top, p);
    p.color = color.withOpacity(.6);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * .5, h * .25),
            width: w * .3,
            height: h * .18),
        p);
  }

  @override
  bool shouldRepaint(covariant _MiniBrickPainter old) =>
      old.color != color;
}
