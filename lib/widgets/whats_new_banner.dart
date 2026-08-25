// lib/widgets/whats_new_banner.dart
//
// Dashboard-facing half of WhatsNewService's quest system. main.dart's
// launch check shows WhatsNewPopup once as the intro; this banner is what
// carries a still-in-progress quest across the sessions after that,
// without re-showing a blocking popup every time the app opens (Concept E
// + Concept C from the design-brainstorm Artifact this system came out
// of). Tapping it reopens the exact same checklist. Renders nothing once
// there's no active entry (no matching version, or already fully claimed).
import 'package:flutter/material.dart';
import '../services/whats_new_service.dart';
import 'whats_new_popup.dart';
import '../theme/app_theme.dart';
import 'brik_icon.dart';

/// Call after any WhatsNewService.completeTask() to surface the result --
/// a quick Brik toast for an ordinary task, or the full quest-complete
/// celebration if that was the last one. A no-op result (task already
/// done, or no active quest) shows nothing.
void showWhatsNewFeedback(BuildContext context, WhatsNewTaskResult result) {
  if (!result.didAnything) return;
  if (result.questCompleted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) QuestCompletePopup.show(context, result);
    });
    return;
  }
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

class WhatsNewBanner extends StatefulWidget {
  const WhatsNewBanner({super.key});
  @override
  State<WhatsNewBanner> createState() => _WhatsNewBannerState();
}

class _WhatsNewBannerState extends State<WhatsNewBanner> {
  @override
  void initState() {
    super.initState();
    WhatsNewService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    WhatsNewService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entry = WhatsNewService.instance.activeEntry;
    if (entry == null) return const SizedBox.shrink();

    final done = WhatsNewService.instance.doneTaskIds(entry.id).length;
    final total = entry.tasks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GestureDetector(
        onTap: () => WhatsNewPopup.show(context, entry),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: BT.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BT.ink, width: BT.bw),
            boxShadow: BT.shadowSm,
          ),
          child: Row(children: [
            Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(color: BT.red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.questTitle,
                    style: BT.body(size: 12.5, color: BT.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$done/$total done · free gift inside',
                    style: BT.mono(size: 9.5, color: BT.tx3)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: BT.tx3, size: 20),
          ]),
        ),
      ),
    );
  }
}
