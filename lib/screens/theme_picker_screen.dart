// lib/screens/theme_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_themes.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../providers/collection.dart';
import '../utils/haptics.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = ThemeService.instance;
    final col = context.watch<CollectionProvider>();
    final bt  = context.bt;
    final unlocked = svc.unlockedThemes(col);

    return Scaffold(
      backgroundColor: bt.surface,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: bt.headerBg,
            border: Border(bottom: BorderSide(color: bt.headerBorder, width: 3)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: bt.primary,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: bt.cardBorder, width: BT.bw),
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: bt.isDark ? BT.ink : BT.ink, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Themes', style: BT.display(size: 26, color: bt.primary)),
              ]),
            ),
          ),
        ),

        // ── Mode toggles ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListenableBuilder(
            listenable: svc,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                color: bt.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bt.cardBorder, width: BT.bw),
              ),
              child: Row(children: [
                _modeBtn(context, svc, ThemeMode.system, '🌓', 'System'),
                _divider(bt),
                _modeBtn(context, svc, ThemeMode.light,  '☀️', 'Light'),
                _divider(bt),
                _modeBtn(context, svc, ThemeMode.dark,   '🌙', 'Dark'),
              ]),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Themes follow your mode setting above. Earn themed palettes by building your collection.',
            style: BT.mono(size: 10, color: bt.tx3),
          ),
        ),

        const SizedBox(height: 12),

        // ── Theme grid ───────────────────────────────────────────────────────
        Expanded(
          child: ListenableBuilder(
            listenable: svc,
            builder: (_, __) => GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: allThemeMeta.length,
              itemBuilder: (_, i) {
                final meta    = allThemeMeta[i];
                final colors  = BrikColors.forTheme(meta.id);
                final isLocked   = !unlocked.contains(meta.id);
                final isSelected = svc.currentTheme == meta.id;
                return _ThemeCard(
                  meta: meta,
                  colors: colors,
                  isLocked: isLocked,
                  isSelected: isSelected,
                  onTap: isLocked ? null : () {
                    BrikHaptics.medium();
                    svc.setTheme(meta.id);
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _modeBtn(BuildContext context, ThemeService svc,
      ThemeMode mode, String emoji, String label) {
    final bt       = context.bt;
    final selected = svc.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          BrikHaptics.selection();
          svc.setMode(mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? bt.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: BT.mono(size: 9,
                    color: selected
                        ? (bt.isDark ? BT.ink : BT.ink)
                        : bt.tx3)),
          ]),
        ),
      ),
    );
  }

  Widget _divider(BrikStaxColors bt) =>
      Container(width: 1, height: 40, color: bt.surface3);
}

// ── Theme preview card ────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final BrikThemeMeta  meta;
  final BrikStaxColors colors;
  final bool           isLocked;
  final bool           isSelected;
  final VoidCallback?  onTap;

  const _ThemeCard({
    required this.meta,
    required this.colors,
    required this.isLocked,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bt = context.bt;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bt.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : bt.cardBorder,
            width: isSelected ? 3 : BT.bw,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: colors.primary.withOpacity(.4),
                  offset: const Offset(3, 3))]
              : [BoxShadow(color: bt.shadowColor.withOpacity(.3),
                  offset: const Offset(2, 2))],
        ),
        child: Column(children: [
          // ── Mini preview ────────────────────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _MiniPreview(colors: colors, isLocked: isLocked),
            ),
          ),

          // ── Label ───────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: bt.surface3, width: 1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(meta.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(child: Text(meta.name,
                    style: BT.body(size: 13, color: bt.tx),
                    overflow: TextOverflow.ellipsis)),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('ON',
                        style: BT.mono(size: 7,
                            color: colors.isDark ? BT.ink : BT.ink)),
                  ),
                if (isLocked)
                  Icon(Icons.lock, size: 14, color: bt.tx3),
              ]),
              const SizedBox(height: 3),
              Text(
                isLocked ? meta.unlockCondition : meta.description,
                style: BT.mono(size: 9, color: bt.tx3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Mini app preview inside each card ────────────────────────────────────────
class _MiniPreview extends StatelessWidget {
  final BrikStaxColors colors;
  final bool isLocked;

  const _MiniPreview({required this.colors, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(color: colors.surface),

        // Mini header
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 28,
            color: colors.headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(
                color: colors.primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Container(width: 40, height: 6,
                  decoration: BoxDecoration(color: colors.primary,
                      borderRadius: BorderRadius.circular(2))),
            ]),
          ),
        ),

        // Mini card
        Positioned(
          top: 36, left: 8, right: 8,
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.cardBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 30, height: 4,
                    color: colors.tx3.withOpacity(.5)),
                const SizedBox(height: 4),
                Container(width: 50, height: 6,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),

        // Mini row
        Positioned(
          top: 88, left: 8, right: 8,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              Container(width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 6),
              Column(mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 40, height: 4,
                    color: colors.tx.withOpacity(.6)),
                const SizedBox(height: 3),
                Container(width: 25, height: 3,
                    color: colors.tx3.withOpacity(.4)),
              ]),
            ]),
          ),
        ),

        // Mini nav
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 26,
            color: colors.navBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: i == 0 ? colors.navActive : colors.navInactive,
                  shape: BoxShape.circle,
                ),
              )),
            ),
          ),
        ),

        // Lock overlay
        if (isLocked)
          Container(
            color: Colors.black.withOpacity(.55),
            child: const Center(
              child: Icon(Icons.lock, color: Colors.white, size: 28),
            ),
          ),
      ],
    );
  }
}
