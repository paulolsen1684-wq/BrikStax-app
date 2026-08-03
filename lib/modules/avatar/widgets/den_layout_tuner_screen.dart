// lib/modules/avatar/widgets/den_layout_tuner_screen.dart
//
// Dev-only tool (Settings > Developer, same gate as PixelItemTunerScreen)
// for the Den's two shared placement objects -- the whole avatar figure,
// and the equipped item's own floor spot -- see ground_accessory.dart's
// DenLayoutTuning/denAvatarRect/groundAccessoryWidget. Unlike
// PixelItemTunerScreen (one offset/scale PER cosmetic id), there are only
// ever these two objects here: moving "Avatar" moves every user's figure
// in the Den the same way, moving "Item" moves every equipped item the
// same way, since that's how the Den's layout actually works (not
// per-cosmetic).
//
// Embeds the REAL DenSceneContent widget for the preview (same widget
// BrickDenScreen and the Avatar Editor's Den tab use) so tuning happens
// against the actual scene, furniture, and background art -- not a mockup.
// Live edits go through DenLayoutTuning, a runtime-only global (see its doc
// comment for why: DenSceneContent reads AchievementService/
// CollectionProvider directly, there's no prop path to inject an override).
// That global is cleared in dispose() so leaving this screen can't leave
// stale offsets affecting Den rendering elsewhere in the app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'den_scene.dart';
import 'ground_accessory.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

enum _Obj { avatar, item }

class DenLayoutTunerScreen extends StatefulWidget {
  const DenLayoutTunerScreen({super.key});
  @override State<DenLayoutTunerScreen> createState() => _State();
}

class _State extends State<DenLayoutTunerScreen> {
  _Obj _obj = _Obj.avatar;
  Offset? _gestureStartFocal;
  late double _startOffsetX, _startOffsetY, _startScale;

  // pxd for a 504-wide scene (matches den_share_screen.dart's fixed card
  // width) -- used only to convert this screen's own drag pixels into the
  // same pxd-relative unit denAvatarRect/groundAccessoryWidget expect.
  // DenSceneContent computes its own pxd internally from its actual
  // rendered width, which may differ slightly on some devices; close
  // enough for dragging by feel, exact values get typed in precisely via
  // the numeric fields below if needed.
  static const double _pxd = 504 / 72;

  double get _offsetX => _obj == _Obj.avatar
      ? (DenLayoutTuning.avatarOffsetX ?? 0) : (DenLayoutTuning.itemOffsetX ?? 0);
  double get _offsetY => _obj == _Obj.avatar
      ? (DenLayoutTuning.avatarOffsetY ?? 0) : (DenLayoutTuning.itemOffsetY ?? 0);
  double get _scale => _obj == _Obj.avatar
      ? (DenLayoutTuning.avatarScale ?? 1) : (DenLayoutTuning.itemScale ?? 1);

  void _setValues({required double offsetX, required double offsetY, required double scale}) {
    setState(() {
      if (_obj == _Obj.avatar) {
        DenLayoutTuning.avatarOffsetX = offsetX;
        DenLayoutTuning.avatarOffsetY = offsetY;
        DenLayoutTuning.avatarScale   = scale;
      } else {
        DenLayoutTuning.itemOffsetX = offsetX;
        DenLayoutTuning.itemOffsetY = offsetY;
        DenLayoutTuning.itemScale   = scale;
      }
      DenLayoutTuning.generation++;
    });
  }

  @override
  void dispose() {
    // See file header -- these are global and affect every Den render in
    // the app, not just this screen, so they must not survive leaving it.
    DenLayoutTuning.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        title: Text('Den Layout Tuner', style: BT.display(size: 20, color: bt.tx)),
        backgroundColor: bt.surface,
        actions: [
          IconButton(
            tooltip: 'Copy overrides',
            icon: const Icon(Icons.copy_all),
            onPressed: _hasAnyOverride() ? _copyOverrides : null,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _objChips(bt),
          ),
          Expanded(
            child: GestureDetector(
              onScaleStart: (details) {
                _startOffsetX = _offsetX;
                _startOffsetY = _offsetY;
                _startScale   = _scale;
                _gestureStartFocal = details.focalPoint;
              },
              onScaleUpdate: (details) {
                if (_gestureStartFocal == null) return;
                final d = details.focalPoint - _gestureStartFocal!;
                _setValues(
                  offsetX: _startOffsetX + d.dx / _pxd,
                  offsetY: _startOffsetY + d.dy / _pxd,
                  scale:   (_startScale * details.scale).clamp(0.2, 4.0),
                );
              },
              onScaleEnd: (_) => _gestureStartFocal = null,
              // DenSceneContent scrolls internally (SingleChildScrollView
              // for the stats below the scene) -- that's fine, it's a
              // DESCENDANT scrollable, not an ancestor of this
              // GestureDetector, so it can't contest the drag the way the
              // per-item tuner's ListView bug did (see that file's history).
              child: const DenSceneContent(),
            ),
          ),
          Text('Drag to move, pinch to scale. Tuning "${_obj == _Obj.avatar ? 'Avatar' : 'Item'}" only.',
              textAlign: TextAlign.center,
              style: BT.mono(size: 11, color: bt.tx3)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _numericPanel(bt),
          ),
        ]),
      ),
    );
  }

  bool _hasAnyOverride() =>
      DenLayoutTuning.avatarOffsetX != null || DenLayoutTuning.avatarOffsetY != null ||
      DenLayoutTuning.avatarScale   != null || DenLayoutTuning.itemOffsetX  != null ||
      DenLayoutTuning.itemOffsetY   != null || DenLayoutTuning.itemScale   != null;

  Widget _objChips(BrikStaxColors bt) => Wrap(spacing: 8, children: [
    for (final o in _Obj.values)
      GestureDetector(
        onTap: () => setState(() => _obj = o),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: o == _obj ? bt.primary : bt.cardBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: Text(o == _Obj.avatar ? 'Avatar' : 'Item',
              style: BT.body(size: 14, color: bt.tx, weight: FontWeight.w700)),
        ),
      ),
  ]);

  Widget _numericPanel(BrikStaxColors bt) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _numField(bt, 'offsetX', _offsetX, (v) => _setValues(offsetX: v, offsetY: _offsetY, scale: _scale)),
      _numField(bt, 'offsetY', _offsetY, (v) => _setValues(offsetX: _offsetX, offsetY: v, scale: _scale)),
      _numField(bt, 'scale',   _scale,   (v) => _setValues(offsetX: _offsetX, offsetY: _offsetY, scale: v.clamp(0.2, 4.0))),
      const SizedBox(height: 8),
      Row(children: [
        TextButton(
          onPressed: () => _setValues(offsetX: 0, offsetY: 0, scale: 1),
          child: Text('Reset ${_obj == _Obj.avatar ? 'Avatar' : 'Item'}',
              style: BT.body(size: 13, color: bt.tx2, weight: FontWeight.w600)),
        ),
        const Spacer(),
        Text('x: ${_offsetX.toStringAsFixed(2)}  y: ${_offsetY.toStringAsFixed(2)}  scale: ${_scale.toStringAsFixed(3)}',
            style: BT.mono(size: 10, color: bt.tx3)),
      ]),
    ]),
  );

  Widget _numField(BrikStaxColors bt, String label, double value, void Function(double) onChanged) {
    final controller = TextEditingController(text: value.toStringAsFixed(3));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: BT.mono(size: 12, color: bt.tx2))),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            style: BT.mono(size: 13, color: bt.tx),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: bt.cardBorder, width: BT.bw),
              ),
            ),
            onSubmitted: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ]),
    );
  }

  void _copyOverrides() {
    final buf = StringBuffer();
    buf.writeln('// Avatar: offsetX ${(DenLayoutTuning.avatarOffsetX ?? 0).toStringAsFixed(2)}, '
        'offsetY ${(DenLayoutTuning.avatarOffsetY ?? 0).toStringAsFixed(2)}, '
        'scale ${(DenLayoutTuning.avatarScale ?? 1).toStringAsFixed(3)}');
    buf.writeln('// Item:   offsetX ${(DenLayoutTuning.itemOffsetX ?? 0).toStringAsFixed(2)}, '
        'offsetY ${(DenLayoutTuning.itemOffsetY ?? 0).toStringAsFixed(2)}, '
        'scale ${(DenLayoutTuning.itemScale ?? 1).toStringAsFixed(3)}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied Den layout overrides to clipboard')),
    );
  }
}
