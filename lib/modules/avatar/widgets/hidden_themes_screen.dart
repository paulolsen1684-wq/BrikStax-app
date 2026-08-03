// lib/modules/avatar/widgets/hidden_themes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';
import '../data/hidden_themes.dart';
import '../data/sprite_cosmetics.dart' as sprite;
import '../services/hidden_theme_service.dart';

class HiddenThemesScreen extends StatefulWidget {
  const HiddenThemesScreen({super.key});
  @override State<HiddenThemesScreen> createState() => _State();
}

class _State extends State<HiddenThemesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final col = context.read<CollectionProvider>();
      await HiddenThemeService.instance.checkAndGrant(col);
      if (mounted) setState(() {});
    });
  }

  Color _tierColor(ThemeTier t) => switch (t) {
    ThemeTier.bronze  => const Color(0xFFCD7F32),
    ThemeTier.silver  => const Color(0xFFC0C0C0),
    ThemeTier.gold    => const Color(0xFFFFD700),
    ThemeTier.diamond => const Color(0xFFAAEEFF),
  };

  String _tierLabel(ThemeTier t) => switch (t) {
    ThemeTier.bronze  => 'Bronze',
    ThemeTier.silver  => 'Silver',
    ThemeTier.gold    => 'Gold',
    ThemeTier.diamond => 'Diamond',
  };

  @override
  Widget build(BuildContext context) {
    final bt       = context.bt;
    final col      = context.watch<CollectionProvider>();
    final progress = HiddenThemeService.instance.progressFor(col);

    progress.sort((a, b) {
      if (a.isComplete != b.isComplete) return a.isComplete ? 1 : -1;
      return a.remainingForNext.compareTo(b.remainingForNext);
    });

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
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
                Text('Hidden Themes', style: BT.display(size: 24, color: bt.tx)),
              ]),
            ),
          ),
        ),

        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: progress.length,
          itemBuilder: (_, i) => _themeCard(bt, progress[i]),
        )),
      ]),
    );
  }

  Widget _themeCard(BrikStaxColors bt, ThemeProgress p) {
    final started  = p.matchedAny > 0;
    final tier     = p.nextTier;
    final complete = p.isComplete;

    // Hidden state — not started yet
    if (!started && !complete) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bt.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Row(children: [
          const Text('❓', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hidden theme',
                  style: BT.body(size: 14, color: bt.txMuted)),
              Text(p.theme.hint,
                  style: BT.mono(size: 10, color: bt.tx3)),
            ],
          )),
        ]),
      );
    }

    final tierColor = tier != null
        ? _tierColor(tier.tier)
        : const Color(0xFFAAEEFF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: complete ? const Color(0xFFFFD700) : tierColor,
            width: complete ? 2 : BT.bw),
        boxShadow: complete
            ? [BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(.3),
                offset: const Offset(3, 3))]
            : [BoxShadow(color: bt.shadowColor,
                offset: const Offset(2, 2))],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(p.theme.emoji,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(p.theme.name,
              style: BT.display(size: 16, color: bt.tx))),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: complete
                  ? const Color(0xFFFFD700).withOpacity(.18)
                  : tierColor.withOpacity(.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: complete
                      ? const Color(0xFFFFD700) : tierColor,
                  width: 1.5),
            ),
            child: Text(
              complete
                  ? '✓ Mastered'
                  : '${_tierLabel(tier!.tier)} tier',
              style: BT.mono(size: 9, color: bt.tx),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        if (!complete && tier != null) ...[
          Row(children: [
            Text('${p.currentForNext} / ${tier.required}',
                style: BT.body(size: 13, color: bt.tx)),
            const SizedBox(width: 6),
            if (tier.verifiedOnly)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text('✓ verified only',
                    style: TextStyle(
                        fontSize: 8,
                        color: Color(0xFF2E7D32),
                        fontFamily: 'monospace')),
              ),
            const Spacer(),
            Text(
              p.remainingForNext == 1
                  ? '1 set away!'
                  : '${p.remainingForNext} to go',
              style: BT.mono(size: 10,
                  color: p.remainingForNext == 1
                      ? const Color(0xFFD85A30) : bt.tx3),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.nextProgress,
              backgroundColor: bt.surface2,
              valueColor: AlwaysStoppedAnimation(tierColor),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Builder(builder: (_) {
            final rewardName = sprite.spriteCosmeticsById[tier.rewardCosmetic]?.name;
            return Text(
              '🎁 Reward: ${rewardName ?? tier.rewardCosmetic}',
              style: BT.mono(size: 9, color: bt.tx3),
            );
          }),
        ] else
          Text(
            'All ${p.theme.tiers.length} tiers complete — every reward unlocked!',
            style: BT.mono(size: 10, color: bt.tx2),
          ),
      ]),
    );
  }
}
