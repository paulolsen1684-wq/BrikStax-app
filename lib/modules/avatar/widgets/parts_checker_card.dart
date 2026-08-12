// lib/modules/avatar/widgets/parts_checker_card.dart
//
// Dashboard entry point for PartsCheckerScreen -- same shape and same
// folder as SetLookupCard right next to it (that file's own doc comment
// notes it's not actually avatar-related content; this one isn't either,
// just following the established placement rather than being the one
// screen that breaks the pattern).
import 'package:flutter/material.dart';
import '../../../screens/parts_checker_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class PartsCheckerCard extends StatelessWidget {
  const PartsCheckerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const PartsCheckerScreen())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
          boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(3, 3))],
        ),
        child: Row(children: [
          const Text('🧩', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parts Checker', style: BT.display(size: 15, color: bt.tx)),
              Text('Check a used set for missing pieces',
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
