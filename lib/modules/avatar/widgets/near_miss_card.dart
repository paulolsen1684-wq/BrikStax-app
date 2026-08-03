// lib/modules/avatar/widgets/near_miss_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/collection.dart';
import '../../../theme/app_theme.dart';
import '../services/near_miss.dart';
import 'hidden_themes_screen.dart';

/// Drop this on the dashboard. Shows the single most urgent near-miss as a
/// motivating prompt; renders nothing when there are no near-misses.
class NearMissCard extends StatelessWidget {
  const NearMissCard({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.watch<CollectionProvider>();
    final nm  = NearMissEngine.instance.top(col);
    if (nm == null) return const SizedBox.shrink();

    final urgent = nm.isOneAway;
    final accent = urgent ? const Color(0xFFD85A30) : BT.ink;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const HiddenThemesScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: urgent ? const Color(0xFFFAECE7) : BT.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent, width: urgent ? 2 : BT.bw),
          boxShadow: urgent
              ? [BoxShadow(color: accent.withOpacity(.25),
                  offset: const Offset(3, 3))]
              : BT.shadowSm,
        ),
        child: Row(children: [
          Text(nm.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (urgent)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('SO CLOSE',
                        style: BT.mono(size: 8, color: Colors.white)),
                  ),
                Expanded(child: Text(
                  urgent
                      ? '1 ${nm.unit} from ${nm.title}!'
                      : '${nm.remaining} ${nm.unit} from ${nm.title}',
                  style: BT.body(size: 14, color: accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
              const SizedBox(height: 2),
              Text(
                nm.rewardName != null
                    ? '${nm.detail} · unlocks ${nm.rewardName}'
                    : nm.detail,
                style: BT.mono(size: 9, color: BT.tx3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: nm.progress,
                  backgroundColor: BT.cream2,
                  valueColor: AlwaysStoppedAnimation(accent),
                  minHeight: 6,
                ),
              ),
            ],
          )),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: accent, size: 20),
        ]),
      ),
    );
  }
}
