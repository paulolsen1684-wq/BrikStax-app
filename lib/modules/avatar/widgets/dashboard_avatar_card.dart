// lib/modules/avatar/widgets/dashboard_avatar_card.dart
import 'package:flutter/material.dart';
import '../data/achievements.dart';
import '../data/backgrounds_art.dart' as bgArt;
import '../services/achievement_service.dart';
import '../services/loot_service.dart';
import 'avatar_widget.dart';
import 'avatar_editor.dart';
import 'brick_den.dart';
import 'daily_claim_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

// Split from a single combined widget so the dashboard can place the
// time-sensitive claim banner in a "things to do today" grouping and the
// browsable minifig progress teaser somewhere quieter, instead of always
// welding the two together regardless of layout. Both still read straight
// from AchievementService/LootService, so neither needs props threaded in.

// Was a thin 60px-thumbnail row card buried near the bottom of the
// dashboard scroll (after the news feed) -- moved up to right after the
// Hero and rebuilt at hero scale itself (110px figure). Backdrop is the
// equipped Den's real generated photo (bgArt.denImageAsset) when one
// exists, same photo-forward treatment as the Hero above it, falling back
// to the palette gradient only for the 4 procedural-only background ids.
// Text is fixed white/white70 with a dark gradient scrim behind it rather
// than computed against palette.avatarBg's brightness -- a single flat-
// color brightness check doesn't reliably predict legibility against a
// busy photo the way it does against the gradient fallback, so the scrim
// sidesteps needing to compute it per photo (same reasoning as _Hero).
class MinifigPreviewCard extends StatelessWidget {
  const MinifigPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return ListenableBuilder(
      listenable: AchievementService.instance,
      builder: (_, __) {
        final state  = AchievementService.instance.state;
        final earned = AllAchievements.all
            .where((a) => state.earnedIds.contains(a.id)).toList();
        final total  = AllAchievements.all.length;
        final palette = bgArt.bgPalettes[state.backgroundId] ?? bgArt.bgPalettes['bg_cream']!;
        final imageAsset = bgArt.denImageAsset(state.backgroundId);
        const onBg = Colors.white;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AvatarEditorScreen())),
          child: Container(
            // Explicit height rather than letting content size it -- the
            // right column's Spacer (pushes the Den link to the bottom
            // edge, level with the avatar's own feet) needs a bounded
            // height from its ancestor chain to lay out at all; an
            // unconstrained Row/Container here throws a RenderFlex
            // "unbounded height" error at runtime, not just a visual
            // quirk. 172 comfortably fits the 110px avatar plus its 16+16
            // vertical padding.
            height: 172,
            decoration: BoxDecoration(
              // Gradient is the fallback backdrop (no photo for this bg id)
              // -- when a photo exists it paints over this via the Stack
              // below, so this never shows through in that case.
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [palette.avatarBg, Color.lerp(palette.avatarBg, Colors.black, .25)!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bt.cardBorder, width: 1.5),
              boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              if (imageAsset != null)
                Positioned.fill(
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
              // Scrim applies over EITHER backdrop (photo or the gradient
              // fallback painted by the Container's own decoration above)
              // -- fixed white text needs guaranteed contrast in both
              // cases, and the gradient fallback alone only mildly darkens
              // toward one corner, not enough against a light palette like
              // Plain Cream's near-white avatarBg.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(.30),
                        Colors.black.withOpacity(.70),
                      ],
                    ),
                  ),
                ),
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 4, 16),
                  child: AvatarWidget(
                    state: state, size: 110, animated: true,
                    showBackground: false, // card itself supplies the backdrop
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 16, 16, 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text('My Minifig', style: BT.display(size: 20, color: onBg)),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: onBg.withOpacity(.6), size: 18),
                      ]),
                      const SizedBox(height: 5),
                      Text('${earned.length}/$total achievements',
                          style: BT.mono(size: 10, color: onBg.withOpacity(.75))),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? earned.length / total : 0,
                          backgroundColor: onBg.withOpacity(.15),
                          valueColor: const AlwaysStoppedAnimation(onBg),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (earned.isNotEmpty)
                        Wrap(spacing: 4, runSpacing: 4, children: earned.reversed.take(6)
                            .map((a) => Text(a.emoji,
                                style: const TextStyle(fontSize: 18)))
                            .toList())
                      else
                        Text('Add a set to unlock your first achievement!',
                            style: BT.mono(size: 9, color: onBg.withOpacity(.75))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const BrickDenScreen())),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('🏠 Enter your Den',
                              style: BT.mono(size: 10, color: onBg, weight: FontWeight.w700)),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward, size: 12, color: onBg),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class DailyBrickClaimCard extends StatelessWidget {
  const DailyBrickClaimCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return ListenableBuilder(
      listenable: AchievementService.instance,
      builder: (_, __) {
        final streak   = LootService.instance.streak;
        final canClaim = streak.canClaim;
        // Text drawn directly on `primary` (the claim state) needs to flip
        // per theme the same way SectionHeader's action pill does -- primary
        // is light gold for Classic/darkBrick but a saturated red/blue/green
        // fill for several unlockable themes, so a fixed ink choice would
        // go low-contrast on those.
        final onPrimary = ThemeData.estimateBrightnessForColor(bt.primary) ==
                Brightness.dark
            ? Colors.white
            : BT.ink;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const DailyClaimScreen())),
          child: Container(
            decoration: BoxDecoration(
              color: canClaim ? bt.primary : bt.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: canClaim
                  ? [BoxShadow(color: bt.shadowColor.withOpacity(.3), offset: const Offset(3, 3))]
                  : [],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Text(canClaim ? '🧱' : '✅',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  canClaim ? 'Daily brick ready!' : 'Come back tomorrow',
                  style: BT.body(size: 13,
                      color: canClaim ? onPrimary : bt.txMuted),
                ),
                Text(
                  canClaim
                      ? 'Tap to claim your ${streak.tierLabel}'
                      : '🔥 ${streak.streak} day streak · ${streak.streakMilestoneLabel}',
                  style: BT.mono(size: 9,
                      color: canClaim ? onPrimary.withOpacity(.75) : bt.txMuted),
                ),
              ])),
              if (canClaim)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bt.cardBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Claim',
                      style: BT.mono(size: 9, color: bt.primary, weight: FontWeight.w700)),
                ),
            ]),
          ),
        );
      },
    );
  }
}
