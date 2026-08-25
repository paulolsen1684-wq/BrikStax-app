// lib/widgets/whats_new_popup.dart
//
// Two dialogs for WhatsNewService's quest system:
//  - WhatsNewPopup: the checklist itself -- shown once automatically on
//    first launch after a matching update (main.dart), and reopenable any
//    time from WhatsNewBanner's Dashboard card while the quest is still in
//    progress. Each not-yet-done task row is directly tappable and
//    completes right there (calls WhatsNewService.completeTask() itself)
//    -- this is the actual mechanic for a task like the current
//    'click_to_claim' one, which isn't tied to using any feature.
//    A task completed *elsewhere* instead (see whats_new_service.dart's
//    file header for how to wire one) still just renders as a checkbox
//    here; tapping an already-done row, or one this popup didn't
//    originate the completion for, is a harmless no-op either way, since
//    completeTask() itself is idempotent.
//  - QuestCompletePopup: the celebration for finishing every task. Can
//    fire from inside WhatsNewPopup itself (tapping the last task) or from
//    a hook completed elsewhere via whats_new_banner.dart's
//    showWhatsNewFeedback -- either path, the reward's already been
//    granted by the time this shows, so its button is just "Nice!"
//    dismiss, unlike LootRollWidget's roll-then-claim flow.
//
// WhatsNewPopup wraps its content in an AnimatedBuilder listening to
// WhatsNewService (a ChangeNotifier) so a tap flips that row's checkbox
// immediately without needing to close and reopen the dialog.
//
// Both reuse the same fixed-light BT.* card look every other avatar popup
// (achievement_popup.dart, bundle_popup.dart, loot_roll_widget.dart) uses
// -- always rendered over a black87 barrier, so it never needs to react to
// the app's current theme.
import 'package:flutter/material.dart';
import '../modules/avatar/data/background_cosmetics.dart' as bg;
import '../modules/avatar/data/pixel_cosmetics.dart' as pixel;
import '../modules/avatar/models/avatar_state.dart';
import '../modules/avatar/services/achievement_service.dart';
import '../modules/avatar/widgets/avatar_widget.dart';
import '../services/whats_new_service.dart';
import '../theme/app_theme.dart';
import 'brik_icon.dart';

class WhatsNewPopup extends StatelessWidget {
  final WhatsNewEntry entry;
  final VoidCallback onDone;
  const WhatsNewPopup({super.key, required this.entry, required this.onDone});

  static Future<void> show(BuildContext context, WhatsNewEntry entry) async {
    await WhatsNewService.instance.markIntroSeen(entry.id);
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => WhatsNewPopup(
        entry: entry,
        onDone: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  // Tapping a not-yet-done row completes it right here. If that was the
  // last task, swap this dialog for QuestCompletePopup instead of leaving
  // both stacked -- closes the checklist and opens the celebration in the
  // same gesture rather than needing a second tap to dismiss this one first.
  Future<void> _tapTask(BuildContext context, WhatsNewTask t) async {
    final result = await WhatsNewService.instance.completeTask(t.id);
    if (!context.mounted || !result.didAnything) return;
    if (result.questCompleted) {
      Navigator.of(context).pop();
      QuestCompletePopup.show(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text.rich(TextSpan(children: [
          TextSpan(text: '+${result.taskBriks} '),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: BrikIcon(size: 14, animated: false),
          ),
          const TextSpan(text: ' Quest task complete!'),
        ])),
        duration: const Duration(seconds: 2),
        backgroundColor: BT.ink,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WhatsNewService.instance,
      builder: (context, _) {
        final done = WhatsNewService.instance.doneTaskIds(entry.id);
        final allDone = entry.tasks.every((t) => done.contains(t.id));

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: BT.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadow,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: BT.yellow,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: BT.ink, width: BT.bw),
                  ),
                  child: Text("WHAT'S NEW", style: BT.display(size: 11, color: BT.ink)),
                ),
                const SizedBox(height: 14),

                Text(entry.questTitle,
                    style: BT.display(size: 19), textAlign: TextAlign.center),
                const SizedBox(height: 16),

                ...entry.tasks.map((t) {
                  final isDone = done.contains(t.id);
                  return GestureDetector(
                    onTap: isDone ? null : () => _tapTask(context, t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(
                          width: 20, height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDone ? BT.green : Colors.transparent,
                            border: Border.all(color: BT.ink, width: 2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 13, color: BT.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.label,
                            style: BT.body(size: 13,
                                color: isDone ? BT.tx3 : BT.ink,
                                weight: FontWeight.w600),
                            )),
                        Text.rich(TextSpan(
                          style: BT.mono(size: 10, color: BT.gold),
                          children: [
                            TextSpan(text: '+${t.briksReward} '),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: BrikIcon(size: 10, animated: false),
                            ),
                          ],
                        )),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _RewardCard(cosmeticId: entry.rewardCosmeticId, locked: !allDone),

                const SizedBox(height: 18),
                GestureDetector(
                  onTap: onDone,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BT.ink, width: BT.bw),
                      boxShadow: BT.shadowSm,
                    ),
                    child: Text(allDone ? 'Awesome!' : "Let's Go!",
                        textAlign: TextAlign.center, style: BT.body(size: 16)),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

/// Fires automatically the instant the last task completes -- see
/// whats_new_banner.dart's showWhatsNewFeedback, called from every task
/// hook after awaiting WhatsNewService.completeTask().
class QuestCompletePopup extends StatelessWidget {
  final WhatsNewTaskResult result;
  final VoidCallback onDone;
  const QuestCompletePopup({super.key, required this.result, required this.onDone});

  static Future<void> show(BuildContext context, WhatsNewTaskResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => QuestCompletePopup(
        result: result,
        onDone: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: BT.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BT.ink, width: BT.bw),
          boxShadow: BT.shadow,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('Quest Complete!', style: BT.display(size: 20), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('Every task done -- here\'s your gift.',
              style: BT.mono(size: 11, color: BT.tx3), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _RewardCard(cosmeticId: result.bonusCosmeticId!, locked: false),
          if (result.bonusWasDupe && result.bonusBriks > 0) ...[
            const SizedBox(height: 10),
            Text.rich(TextSpan(
              style: BT.mono(size: 10, color: BT.tx3),
              children: [
                TextSpan(text: 'Already owned -- +${result.bonusBriks} '),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: BrikIcon(size: 10, animated: false),
                ),
                const TextSpan(text: ' instead'),
              ],
            )),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: BT.yellow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BT.ink, width: BT.bw),
                boxShadow: BT.shadowSm,
              ),
              child: Text('Nice!', textAlign: TextAlign.center, style: BT.body(size: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Shared reward-preview card -- resolves [cosmeticId] against either
/// catalog, same lookup shape whats_new_service.dart's grant logic uses.
/// The avatar preview below the name/rarity mirrors achievement_popup.dart's
/// own _previewState pattern exactly: take the player's actual current
/// AvatarState and swap in just the one slot this reward occupies, so what
/// shows is genuinely "your avatar wearing this," not a bare catalog
/// thumbnail. Shown even while [locked] (not earned yet) -- unlike a
/// LootRollWidget-style random roll, this reward is fixed and already
/// fully described (name/rarity/description all show regardless), so
/// previewing it too is consistent, and doubles as an incentive to finish.
class _RewardCard extends StatelessWidget {
  final String cosmeticId;
  final bool locked;
  const _RewardCard({required this.cosmeticId, required this.locked});

  AvatarState _previewState() {
    final base = AchievementService.instance.state;
    final bgC = bg.backgroundCosmeticsById[cosmeticId];
    if (bgC != null && bgC.slot == bg.CosmeticSlot.background) {
      return base.copyWith(backgroundId: bgC.id);
    }
    final pxC = pixel.pixelCosmeticsById[cosmeticId];
    if (pxC != null) {
      return switch (pxC.slot) {
        pixel.PixelSlot.head  => base.copyWith(headId: pxC.id),
        pixel.PixelSlot.hat   => base.copyWith(hatId: pxC.id),
        pixel.PixelSlot.torso => base.copyWith(torsoId: pxC.id),
        pixel.PixelSlot.legs  => base.copyWith(legsId: pxC.id),
        pixel.PixelSlot.item  => base.copyWith(itemId: pxC.id),
      };
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final bgC = bg.backgroundCosmeticsById[cosmeticId];
    final pxC = pixel.pixelCosmeticsById[cosmeticId];
    final name  = bgC?.name ?? pxC?.name ?? cosmeticId;
    final desc  = bgC?.description ?? pxC?.description;
    final color = bgC?.rarity.color ?? pxC?.rarity.color ?? BT.gold;
    final label = bgC?.rarity.label ?? pxC?.rarity.label ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: BT.cream2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(children: [
        Text(locked ? 'FINISH EVERY TASK TO UNLOCK' : '🎁 A GIFT, ON US',
            style: BT.mono(size: 9, color: BT.tx3)),
        const SizedBox(height: 8),
        Text(name, style: BT.display(size: 16), textAlign: TextAlign.center),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(label, style: BT.mono(size: 9, color: color)),
        ),
        const SizedBox(height: 10),
        AvatarWidget(state: _previewState(), size: 110),
        if (desc != null) ...[
          const SizedBox(height: 7),
          Text(desc, style: BT.mono(size: 10, color: BT.tx3), textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}
