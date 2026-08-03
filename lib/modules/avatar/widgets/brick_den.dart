// lib/modules/avatar/widgets/brick_den.dart
//
// Screen chrome only (header, back/share buttons) -- the actual scene,
// showcase, and trophy content lives in den_scene.dart's DenSceneContent,
// which this screen just embeds. That split exists so the Avatar Editor's
// Den tab can embed the exact same scene without a second full-Scaffold
// screen nested inside a TabBarView.
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';
import 'den_scene.dart';
import 'den_share_screen.dart';

class BrickDenScreen extends StatelessWidget {
  const BrickDenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: bt.surface,
            border: Border(
                bottom: BorderSide(
                    color: bt.cardBorder, width: BT.bw)),
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
                Text('The Brick Den',
                    style: BT.display(size: 26, color: bt.tx)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) =>
                               DenShareScreen())),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: BT.yellow,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: BT.ink, width: BT.bw),
                      boxShadow: BT.shadowSm,
                    ),
                    child: const Icon(Icons.ios_share,
                        color: BT.ink, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),

        const Expanded(child: DenSceneContent()),
      ]),
    );
  }
}
