// lib/modules/avatar/widgets/pixel_item_tuner_screen.dart
//
// Dev-only tool (Settings > Developer, same gate as PixelAvatarPreview
// Screen) for fixing outlier items one at a time instead of hand-editing
// numbers in pixel_avatar_widget.dart's shared per-slot geometry -- that
// shared geometry positions/sizes EVERY item in a slot with one formula,
// which was fine for 5 items per slot but started showing outliers once
// the catalog grew to 20-25 per slot (see CLAUDE.md). This screen lets you
// drag/pinch one item at a time (offsetX/offsetY/scale, applied on top of
// the shared slot geometry -- see PixelCosmetic and PixelAvatarWidget
// .overrides) and previews the change live via PixelAvatarWidget's
// overrides param, without touching the real const catalog.
//
// This tool does NOT bake anything into pixel_cosmetics.dart by itself --
// edits only live in SharedPreferences on this device until you use "Copy
// Overrides" to get a paste-ready Dart snippet and hand it back so the
// values can be written into the real PixelCosmetic entries. Until that
// happens, tuning done here doesn't affect any other screen in the app
// (avatar_editor.dart, dashboard cards, etc. all still render the
// un-tuned catalog defaults).
//
// Three tiers of control over the same offsetX/offsetY/scale, added
// 2026-08-23: drag/pinch (coarse, finger-precision only), the D-pad/+-
// nudge buttons below (fine, one-tap steps -- _nudgeStep/_scaleStep),
// and the numeric text fields (exact, type any value). Added because
// dragging can't reliably land on a specific small increment and retyping
// a decimal value for every tiny adjustment is slow -- the nudge buttons
// are the fast path for "a little more to the left" style iteration.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/pixel_cosmetics.dart';
import '../services/achievement_service.dart';
import 'pixel_avatar_widget.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_themes.dart';

class PixelItemTunerScreen extends StatefulWidget {
  const PixelItemTunerScreen({super.key});
  @override State<PixelItemTunerScreen> createState() => _State();
}

class _Ov {
  double offsetX, offsetY, scale;
  _Ov({this.offsetX = 0, this.offsetY = 0, this.scale = 1});
  Map<String, dynamic> toJson() => {'offsetX': offsetX, 'offsetY': offsetY, 'scale': scale};
  factory _Ov.fromJson(Map<String, dynamic> j) => _Ov(
    offsetX: (j['offsetX'] as num?)?.toDouble() ?? 0,
    offsetY: (j['offsetY'] as num?)?.toDouble() ?? 0,
    scale:   (j['scale']   as num?)?.toDouble() ?? 1,
  );
  bool get isDefault => offsetX == 0 && offsetY == 0 && scale == 1;
}

class _State extends State<PixelItemTunerScreen> {
  static const _kPrefsKey = 'pixel_item_tuner_overrides_v1';

  PixelSlot _slot = PixelSlot.hat;
  late String? _selectedId = pixelCosmeticsForSlot(_slot).firstOrNull?.id;
  final Map<String, _Ov> _overrides = {};

  // Frame-step controls, for animated items only: the live ticker cycles
  // frames every ~225ms (900ms / 4), too fast to carefully eyeball whether
  // an individual frame is misaligned -- e.g. the X-Wing secret's 8 frames
  // were each cropped to their OWN alpha bounding box independently and
  // have visibly different aspect ratios, so BoxFit.contain can center
  // each one slightly differently within the same fixed box, reading as a
  // jiggle if you only ever see it cycling at full speed. Pausing swaps in
  // a copyWith(frames: [oneFrame]) override -- since renderFrames.length
  // becomes 1, PixelAvatarWidget's own isAnimated check goes false and it
  // never allocates a ticker for that layer, no separate "paused" flag
  // needed on the widget itself.
  bool _paused = false;
  int _manualFrame = 0;

  // Gesture-start snapshot so drag/pinch deltas are relative to where the
  // gesture began. Both fields are needed: ScaleUpdateDetails.scale is
  // already cumulative from gesture start (Flutter computes it that way),
  // but .focalPointDelta is only the delta since the PREVIOUS update call,
  // not since the gesture started -- using it directly against a fixed
  // start-of-gesture baseline (an earlier bug here) meant only the last
  // frame's tiny movement ever stuck, which looked exactly like the item
  // snapping back to its start position on release. Tracking the actual
  // start focal point and diffing against the current one gives the real
  // cumulative offset.
  _Ov? _gestureBase;
  Offset? _gestureStartFocal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      _overrides.addAll(decoded.map(
          (k, v) => MapEntry(k, _Ov.fromJson(v as Map<String, dynamic>))));
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final nonDefault = {
      for (final e in _overrides.entries)
        if (!e.value.isDefault) e.key: e.value.toJson(),
    };
    await prefs.setString(_kPrefsKey, jsonEncode(nonDefault));
  }

  _Ov _ovFor(String id) => _overrides.putIfAbsent(id, () => _Ov());

  // One-tap step size for the D-pad/scale nudge buttons -- see this file's
  // header doc comment for why these exist alongside drag/pinch and the
  // numeric fields. 0.25 units lands comfortably between "drag" (coarse,
  // several units per finger movement) and "type a value" (exact, but slow
  // to iterate) -- small enough to nudge an item into place a step at a
  // time, big enough that it doesn't take dozens of taps to matter.
  static const double _nudgeStep = 0.25;
  static const double _scaleStep = 0.02;

  void _nudgeOffset(_Ov ov, double dx, double dy) {
    setState(() { ov.offsetX += dx; ov.offsetY += dy; });
    _persist();
  }

  void _nudgeScale(_Ov ov, double d) {
    setState(() { ov.scale = (ov.scale + d).clamp(0.2, 4.0); });
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;
    final items = pixelCosmeticsForSlot(_slot);
    final selected = _selectedId == null ? null : pixelCosmeticsById[_selectedId];
    final ov = selected == null ? null : _ovFor(selected.id);

    // Base avatar comes from the real equipped state so context (how this
    // item sits next to whatever else is equipped) matches reality; only
    // the slot being tuned is swapped to whichever item is selected here.
    final base = AchievementService.instance.state;
    final overridesMap = <String, PixelCosmetic>{
      if (selected != null && ov != null)
        selected.id: selected.copyWith(
          offsetX: ov.offsetX, offsetY: ov.offsetY, scale: ov.scale,
          frames: (_paused && selected.isAnimated)
              ? [selected.renderFrames[_manualFrame.clamp(0, selected.renderFrames.length - 1)]]
              : null,
        ),
    };
    final previewState = PixelAvatarState(
      headId:  _slot == PixelSlot.head  ? selected?.id : base.headId,
      hatId:   _slot == PixelSlot.hat   ? selected?.id : base.hatId,
      torsoId: _slot == PixelSlot.torso ? selected?.id : base.torsoId,
      legsId:  _slot == PixelSlot.legs  ? selected?.id : base.legsId,
      itemId:  _slot == PixelSlot.item  ? selected?.id : base.itemId,
    );

    return Scaffold(
      backgroundColor: bt.surface,
      appBar: AppBar(
        title: Text('Item Position Tuner', style: BT.display(size: 20, color: bt.tx)),
        backgroundColor: bt.surface,
        actions: [
          IconButton(
            tooltip: 'Copy overrides',
            icon: const Icon(Icons.copy_all),
            onPressed: _overrides.values.every((o) => o.isDefault) ? null : _copyOverrides,
          ),
        ],
      ),
      // Was a single ListView -- but that made the preview's drag gesture a
      // DESCENDANT of a scrollable, so a single-finger drag lost the gesture
      // arena to the list's own scroll recognizer and only two-finger pinch
      // (which never competes with scrolling) ever reached the pan/scale
      // handler below. Fix: take the preview out of any scrollable ancestor
      // entirely -- chips above and the numeric panel below each get their
      // own small scroll region if needed, but the preview itself sits in
      // a plain Column slot with nothing above it in the widget tree that
      // could contest a one-finger drag.
      body: SafeArea(
        child: Column(children: [
          // Was maxHeight: 150 -- capped here specifically so the preview
          // below (the thing actually being tuned) gets the lion's share of
          // vertical space rather than the slot/item picker chips.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(children: [
                _slotChips(bt),
                const SizedBox(height: 8),
                _itemChips(bt, items),
              ]),
            ),
          ),
          Expanded(
            // Preview used to be a fixed 220px regardless of screen size,
            // which left a lot of dead space on taller phones -- size it off
            // the actual space this Expanded is given instead (capped so it
            // doesn't get absurd on tablets), leaving the +40/+80 margins
            // room for the card's padding and the item-band area to the
            // figure's right.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final previewSize = (constraints.maxWidth - 40)
                    .clamp(120.0, constraints.maxHeight - 80)
                    .clamp(120.0, 480.0);
                final unit = previewSize / PixelAvatarWidget.canvasHeightUnits;
                return Center(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      if (ov == null) return;
                      _gestureBase = _Ov(offsetX: ov.offsetX, offsetY: ov.offsetY, scale: ov.scale);
                      _gestureStartFocal = details.focalPoint;
                    },
                    onScaleUpdate: (details) {
                      if (ov == null || _gestureBase == null || _gestureStartFocal == null) return;
                      final totalDelta = details.focalPoint - _gestureStartFocal!;
                      setState(() {
                        ov.offsetX = _gestureBase!.offsetX + totalDelta.dx / unit;
                        ov.offsetY = _gestureBase!.offsetY + totalDelta.dy / unit;
                        ov.scale   = (_gestureBase!.scale * details.scale).clamp(0.2, 4.0);
                      });
                    },
                    onScaleEnd: (_) {
                      _gestureBase = null;
                      _gestureStartFocal = null;
                      _persist();
                    },
                    child: Container(
                      width: previewSize + 40, height: previewSize + 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bt.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: bt.cardBorder, width: BT.bw),
                        boxShadow: [BoxShadow(color: bt.shadowColor, offset: const Offset(4, 4))],
                      ),
                      child: PixelAvatarWidget(
                        state: previewState,
                        size: previewSize,
                        overrides: overridesMap,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (selected != null && selected.isAnimated)
            _frameStepper(bt, selected),
          if (ov != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: _numericPanel(bt, selected!, ov),
            ),
        ]),
      ),
    );
  }

  Widget _slotChips(BrikStaxColors bt) => Wrap(spacing: 8, runSpacing: 8, children: [
    for (final s in PixelSlot.values)
      GestureDetector(
        onTap: () => setState(() {
          _slot = s;
          _selectedId = pixelCosmeticsForSlot(s).firstOrNull?.id;
          _manualFrame = 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: s == _slot ? bt.primary : bt.cardBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: bt.cardBorder, width: BT.bw),
          ),
          child: Text(s.name, style: BT.body(size: 13, color: bt.tx, weight: FontWeight.w600)),
        ),
      ),
  ]);

  Widget _itemChips(BrikStaxColors bt, List<PixelCosmetic> items) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in items)
          GestureDetector(
            onTap: () => setState(() {
              _selectedId = c.id;
              _manualFrame = 0;
              _paused = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.id == _selectedId ? bt.primary : bt.cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: (_overrides[c.id]?.isDefault ?? true) ? bt.cardBorder : bt.primary,
                  width: (_overrides[c.id]?.isDefault ?? true) ? BT.bw : BT.bw * 2,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                // Marks items with real animation frames (see
                // PixelCosmetic.isAnimated) so they're easy to spot in a
                // 20+ item list without opening each one.
                if (c.isAnimated) ...[
                  Icon(Icons.motion_photos_on,
                      size: 13, color: c.id == _selectedId ? bt.tx : bt.tx3),
                  const SizedBox(width: 4),
                ],
                Text(c.name, style: BT.body(size: 12, color: bt.tx)),
              ]),
            ),
          ),
      ]);

  // Pause/step controls for animated items -- see _paused/_manualFrame's
  // doc comment for why this exists (the live ~225ms-per-frame cycle is
  // too fast to catch a single misaligned frame).
  Widget _frameStepper(BrikStaxColors bt, PixelCosmetic selected) {
    final total = selected.renderFrames.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bt.cardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: bt.cardBorder, width: BT.bw),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () => setState(() => _paused = !_paused),
          child: Icon(_paused ? Icons.play_arrow : Icons.pause,
              size: 20, color: bt.tx),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: !_paused ? null : () => setState(() {
            _manualFrame = (_manualFrame - 1 + total) % total;
          }),
          child: Icon(Icons.chevron_left, size: 20,
              color: _paused ? bt.tx : bt.txMuted),
        ),
        SizedBox(
          width: 54,
          child: Text('Frame ${(_manualFrame % total) + 1}/$total',
              textAlign: TextAlign.center,
              style: BT.mono(size: 10, color: bt.tx2)),
        ),
        GestureDetector(
          onTap: !_paused ? null : () => setState(() {
            _manualFrame = (_manualFrame + 1) % total;
          }),
          child: Icon(Icons.chevron_right, size: 20,
              color: _paused ? bt.tx : bt.txMuted),
        ),
      ]),
    );
  }

  // Deliberately compact -- this panel used to eat a large fixed chunk of
  // vertical space (16px padding all round, 12px gaps, 16px title) that
  // competed directly with the preview above for room on short screens.
  // Shrunk to free that space for the preview via the LayoutBuilder above.
  Widget _numericPanel(BrikStaxColors bt, PixelCosmetic selected, _Ov ov) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bt.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bt.cardBorder, width: BT.bw),
    ),
    // Row, not Column -- the D-pad/scale nudge block sits to the left of
    // the existing name/fields/reset column instead of stacking above it,
    // spending horizontal space (which this panel has plenty of) instead
    // of vertical space (which the preview above is already fighting for,
    // see this method's own long-standing "deliberately compact" comment).
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _nudgeControls(bt, ov),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(selected.name, style: BT.display(size: 13, color: bt.tx)),
          const SizedBox(height: 4),
          _numField(bt, 'offsetX', ov.offsetX, (v) => setState(() => ov.offsetX = v)),
          _numField(bt, 'offsetY', ov.offsetY, (v) => setState(() => ov.offsetY = v)),
          _numField(bt, 'scale',   ov.scale,   (v) => setState(() => ov.scale   = v.clamp(0.2, 4.0))),
          Row(children: [
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () { setState(() { ov.offsetX = 0; ov.offsetY = 0; ov.scale = 1; }); _persist(); },
              child: Text('Reset', style: BT.body(size: 12, color: bt.tx2, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'x: ${ov.offsetX.toStringAsFixed(2)}  y: ${ov.offsetY.toStringAsFixed(2)}  s: ${ov.scale.toStringAsFixed(3)}',
                style: BT.mono(size: 9, color: bt.tx3),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ]),
      ),
    ]),
  );

  // D-pad (offsetX/offsetY) + grow/shrink (scale) one-tap nudge buttons --
  // see _nudgeStep/_nudgeOffset/_nudgeScale above. offsetY follows the same
  // down-is-positive convention the drag gesture above already uses
  // (details.focalPoint's dy), so the down arrow increases it and the up
  // arrow decreases it, matching what dragging down/up already does.
  Widget _nudgeControls(BrikStaxColors bt, _Ov ov) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _nudgeBtn(bt, Icons.keyboard_arrow_up, () => _nudgeOffset(ov, 0, -_nudgeStep)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _nudgeBtn(bt, Icons.keyboard_arrow_left, () => _nudgeOffset(ov, -_nudgeStep, 0)),
        const SizedBox(width: 26),
        _nudgeBtn(bt, Icons.keyboard_arrow_right, () => _nudgeOffset(ov, _nudgeStep, 0)),
      ]),
      _nudgeBtn(bt, Icons.keyboard_arrow_down, () => _nudgeOffset(ov, 0, _nudgeStep)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _nudgeBtn(bt, Icons.remove, () => _nudgeScale(ov, -_scaleStep), tooltip: 'Shrink'),
        const SizedBox(width: 3),
        _nudgeBtn(bt, Icons.add, () => _nudgeScale(ov, _scaleStep), tooltip: 'Grow'),
      ]),
    ],
  );

  Widget _nudgeBtn(BrikStaxColors bt, IconData icon, VoidCallback onTap, {String? tooltip}) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bt.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: bt.cardBorder, width: BT.bw),
        ),
        child: Icon(icon, size: 15, color: bt.tx),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Widget _numField(BrikStaxColors bt, String label, double value, void Function(double) onChanged) {
    final controller = TextEditingController(text: value.toStringAsFixed(3));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        SizedBox(width: 54, child: Text(label, style: BT.mono(size: 11, color: bt.tx2))),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            style: BT.mono(size: 12, color: bt.tx),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: bt.cardBorder, width: BT.bw),
              ),
            ),
            onSubmitted: (text) {
              final parsed = double.tryParse(text);
              if (parsed != null) { onChanged(parsed); _persist(); }
            },
          ),
        ),
      ]),
    );
  }

  void _copyOverrides() {
    final buf = StringBuffer();
    final entries = _overrides.entries.where((e) => !e.value.isDefault).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final e in entries) {
      final o = e.value;
      buf.writeln("'${e.key}': offsetX: ${o.offsetX.toStringAsFixed(2)}, "
          "offsetY: ${o.offsetY.toStringAsFixed(2)}, scale: ${o.scale.toStringAsFixed(3)},");
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${entries.length} override(s) to clipboard')),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
