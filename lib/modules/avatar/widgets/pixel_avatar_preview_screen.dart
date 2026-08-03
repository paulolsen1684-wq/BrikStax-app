// lib/modules/avatar/widgets/pixel_avatar_preview_screen.dart
//
// Dev-only screen to see the new pixel-art assets actually composited on a
// figure and cycle through combinations -- not part of the real avatar
// editor, not reachable by normal users (Settings only shows the entry
// point when DevMode.instance.isOn). Exists purely so real, on-device
// screenshots of PixelAvatarWidget's output are possible before this
// becomes the live system.
import 'package:flutter/material.dart';
import '../data/pixel_cosmetics.dart';
import 'pixel_avatar_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class PixelAvatarPreviewScreen extends StatefulWidget {
  const PixelAvatarPreviewScreen({super.key});
  @override State<PixelAvatarPreviewScreen> createState() => _State();
}

class _State extends State<PixelAvatarPreviewScreen> {
  int _headIdx = 0, _hatIdx = 0, _torsoIdx = 0, _legsIdx = 0;

  late final _heads  = pixelCosmeticsForSlot(PixelSlot.head);
  late final _hats   = pixelCosmeticsForSlot(PixelSlot.hat);
  late final _torsos = pixelCosmeticsForSlot(PixelSlot.torso);
  late final _legs   = pixelCosmeticsForSlot(PixelSlot.legs);

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final state = PixelAvatarState(
      headId:  _heads.isNotEmpty  ? _heads[_headIdx].id   : null,
      hatId:   _hats.isNotEmpty   ? _hats[_hatIdx].id     : null,
      torsoId: _torsos.isNotEmpty ? _torsos[_torsoIdx].id : null,
      legsId:  _legs.isNotEmpty   ? _legs[_legsIdx].id    : null,
    );

    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        title: Text('Pixel Avatar Preview', style: BT.display(size: 20, color: bt.tx)),
        backgroundColor: bt.surface,
      ),
      body: SafeArea(
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bt.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bt.cardBorder, width: BT.bw),
              boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(4, 4))],
            ),
            child: PixelAvatarWidget(state: state, size: 240),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _slotRow(bt, 'Head',  _heads,  _headIdx,  (i) => setState(() => _headIdx = i)),
                _slotRow(bt, 'Hat',   _hats,   _hatIdx,   (i) => setState(() => _hatIdx = i)),
                _slotRow(bt, 'Torso', _torsos, _torsoIdx, (i) => setState(() => _torsoIdx = i)),
                _slotRow(bt, 'Legs',  _legs,   _legsIdx,  (i) => setState(() => _legsIdx = i)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _slotRow(BrikStaxColors bt, String label, List<PixelCosmetic> items,
      int selected, void Function(int) onSelect) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: BT.mono(size: 10, color: bt.tx3, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (int i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: i == selected ? bt.primary : bt.cardBg,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: bt.cardBorder, width: BT.bw),
                ),
                child: Text(items[i].name, style: BT.body(size: 12, color: bt.tx)),
              ),
            ),
        ]),
      ]),
    );
  }
}
