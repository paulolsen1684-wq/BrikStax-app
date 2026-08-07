// lib/modules/avatar/widgets/set_lookup_card.dart
//
// Dashboard entry point for SetLookupScreen. Always shown (unlike
// WishlistDashboardCard, which hides when the wishlist is empty) since
// there's no "empty state" for a lookup tool -- it's useful the very first
// time someone opens the app, before they've added or wishlisted anything.
//
// Usage on the dashboard (as a sliver):
//   const SliverToBoxAdapter(
//     child: Padding(
//       padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
//       child: SetLookupCard(),
//     ),
//   ),
import 'package:flutter/material.dart';
import '../../../screens/set_lookup_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class SetLookupCard extends StatelessWidget {
  const SetLookupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const SetLookupScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        child: Row(children: [
          const Text('🔍', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Lookup', style: BT.display(size: 15, color: bt.tx)),
              Text('Pieces, price, retirement status — any set',
                  style: BT.mono(size: 9, color: bt.tx3),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          Icon(Icons.chevron_right, color: bt.txMuted, size: 22),
        ]),
      ),
    );
  }
}
