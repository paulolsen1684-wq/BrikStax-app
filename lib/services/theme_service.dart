// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';
import '../providers/collection.dart';
import '../modules/avatar/services/dev_mode.dart';
import 'package:flutter/services.dart';
 
 
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final instance = ThemeService._();
 
  static const _themeKey = 'brik_theme';
  // ThemeMode is always inferred from the theme's isDark flag — never stored.
 
  BrikTheme _theme = BrikTheme.darkBrick;
 
  BrikTheme get currentTheme => _theme;
  ThemeMode get themeMode => _inferMode(_theme);
 
  String get themeName =>
      allThemeMeta.firstWhere((m) => m.id == _theme).name;
 
  ThemeMode _inferMode(BrikTheme t) =>
      BrikColors.forTheme(t).isDark ? ThemeMode.dark : ThemeMode.light;
 
  // ── Init from prefs ────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    _theme = BrikTheme.values.firstWhere(
      (t) => t.name == savedTheme,
      orElse: () => BrikTheme.darkBrick,
    );
    await prefs.remove('brik_theme_mode');
    notifyListeners();
  }
 
  // ── Apply a theme ──────────────────────────────────────────────────────────
  Future<void> setTheme(BrikTheme theme) async {
    _theme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }
 
  // ── setMode kept for API compatibility but is now a no-op ─────────────────
  Future<void> setMode(ThemeMode mode) async {}
 
  // ── Build ThemeData ────────────────────────────────────────────────────────
  ThemeData buildTheme(BrikTheme t) {
    final c = BrikColors.forTheme(t);
    final border = BorderSide(color: c.cardBorder, width: 2.5);
    return ThemeData(
      useMaterial3: true,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.surface,
      extensions: [c],
      colorScheme: c.isDark
          ? ColorScheme.dark(
              primary: c.primary, secondary: c.primary,
              surface: c.surface2, onPrimary: Colors.white)
          : ColorScheme.light(
              primary: c.primary, secondary: c.primary,
              surface: c.cardBg, onPrimary: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: c.headerBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: c.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: c.cardBg, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), side: border),
      ),
      dividerTheme: DividerThemeData(
          color: c.surface3, thickness: 1.5, space: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.inputFill,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.surface3, width: 2)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.surface3, width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.primary, width: 2.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.primary),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: border),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20)),
          side: border,
        ),
      ),
    );
  }
 
  ThemeData get lightTheme => buildTheme(
      BrikColors.forTheme(_theme).isDark ? BrikTheme.classic : _theme);
  ThemeData get darkTheme  => buildTheme(
      BrikColors.forTheme(_theme).isDark ? _theme : BrikTheme.darkBrick);
  ThemeData get activeTheme => buildTheme(_theme);
 
  // ── Unlock check ───────────────────────────────────────────────────────────
  // Dev mode short-circuits this to unlock every theme, regardless of
  // collection contents. See DevMode.isOn (toggled via the magic set number).
  Set<BrikTheme> unlockedThemes(CollectionProvider col) {
    if (DevMode.instance.isOn) {
      return BrikTheme.values.toSet();
    }
 
    final sets   = col.sets;
    final market = col.totalMarket;
    final unlocked = <BrikTheme>{BrikTheme.classic, BrikTheme.darkBrick};
 
    if (sets.where((s) =>
        s.theme?.toLowerCase().contains('star wars') ?? false).length >= 5)
      unlocked.add(BrikTheme.starWars);
 
    if (sets.where((s) =>
        s.theme?.toLowerCase().contains('ninjago') ?? false).length >= 3)
      unlocked.add(BrikTheme.ninjago);
 
    if (sets.where((s) =>
        s.theme?.toLowerCase().contains('city') ?? false).length >= 10)
      unlocked.add(BrikTheme.city);
 
    if (sets.any((s) =>
        (s.theme?.toLowerCase().contains('botanical') ?? false) ||
        (s.subtheme?.toLowerCase().contains('botanical') ?? false)))
      unlocked.add(BrikTheme.botanical);
 
    if (market >= 10000) unlocked.add(BrikTheme.icons);
 
    if (sets.any((s) =>
        (s.theme?.toLowerCase().contains('space') ?? false) ||
        (s.theme?.toLowerCase().contains('classic') ?? false)))
      unlocked.add(BrikTheme.spaceClassic);
 
    return unlocked;
  }
}