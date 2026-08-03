// lib/modules/avatar/widgets/wishlist_dashboard_card.dart
//
// A dashboard card that surfaces wishlist items at/near their target price.
// Shows nothing if no items are close, so it never clutters an empty wishlist.
//
// Usage on the dashboard (as a sliver):
//   const SliverToBoxAdapter(
//     child: Padding(
//       padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
//       child: WishlistDashboardCard(),
//     ),
//   ),
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/wishlist_service.dart';
import '../../../screens/wishlist_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class WishlistDashboardCard extends StatelessWidget {
  const WishlistDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt  = context.bt;
    final svc = context.watch<WishlistService>();
    final atTarget  = svc.atTarget;
    final near      = svc.nearTarget();

    if (svc.items.isEmpty) return const SizedBox.shrink();

    final hasHot   = atTarget.isNotEmpty;
    final showItems = hasHot ? atTarget : near;

    if (showItems.isEmpty) {
      return _entryChip(context, bt, svc.items.length);
    }

    final lead = showItems.first;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const WishlistScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasHot ? const Color(0xFFE1F5EE) : bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasHot ? BT.green : bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        child: Row(children: [
          Text(hasHot ? '🎯' : '👀', style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasHot
                    ? '${atTarget.length} wishlist ${atTarget.length == 1 ? "set" : "sets"} at target!'
                    : 'A wishlist set is close to target',
                style: BT.display(size: 15,
                    color: hasHot ? BT.green : bt.tx),
              ),
              Text(
                lead.name.isNotEmpty ? lead.name : 'Set ${lead.num}',
                style: BT.mono(size: 9, color: bt.tx3),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          Icon(Icons.chevron_right, color: bt.txMuted, size: 22),
        ]),
      ),
    );
  }

  Widget _entryChip(BuildContext context, BrikStaxColors bt, int count) =>
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const WishlistScreen())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bt.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
            boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
          ),
          child: Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wishlist', style: BT.display(size: 15, color: bt.tx)),
                Text('$count ${count == 1 ? "set" : "sets"} tracked · tap to check prices',
                    style: BT.mono(size: 9, color: bt.tx3)),
              ],
            )),
            Icon(Icons.chevron_right, color: bt.txMuted, size: 22),
          ]),
        ),
      );
}
