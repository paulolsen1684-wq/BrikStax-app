// lib/theme/app_theme.dart — BrikStax Brick UI Design System
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── BT static class ───────────────────────────────────────────────────────────
class BT {
  BT._();

  static const cream    = Color(0xFFF2EFE9);
  static const cream2   = Color(0xFFE8E4DC);
  static const cream3   = Color(0xFFDDD8CE);
  static const white    = Color(0xFFFFFFFF);
  static const yellow   = Color(0xFFFFCB00);
  static const yellow2  = Color(0xFFFFD740);
  static const yellow3  = Color(0xFFE6B800);
  static const yellowBg = Color(0xFFFFFBEA);
  static const ink      = Color(0xFF0A0907);
  static const ink2     = Color(0xFF1C1810);
  static const red      = Color(0xFFE3000B);
  static const redBg    = Color(0xFFFEEEF0);
  static const green    = Color(0xFF00A850);
  static const greenBg  = Color(0xFFE8F9EF);
  static const blue     = Color(0xFF006CB7);
  static const blueBg   = Color(0xFFE8F0FF);
  static const orange   = Color(0xFFFF6B00);
  static const gold     = Color(0xFFB8860B);
  static const tx       = Color(0xFF0A0907);
  static const tx2      = Color(0xFF555555);
  static const tx3      = Color(0xFF888888);
  static const txMuted  = Color(0xFFB0A898);

  static const bw         = 2.5;
  static const borderSide = BorderSide(color: ink, width: bw);

  static const shadow   = [BoxShadow(color: ink, offset: Offset(3, 3))];
  static const shadowSm = [BoxShadow(color: ink, offset: Offset(2, 2))];
  static const shadowLg = [BoxShadow(color: ink, offset: Offset(5, 5))];

  static TextStyle display({double size = 24, Color color = ink}) =>
      GoogleFonts.bebasNeue(fontSize: size, color: color, letterSpacing: size * .04);

  static TextStyle body({double size = 14, Color color = ink,
      FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, color: color, fontWeight: weight);

  static TextStyle mono({double size = 12, Color color = tx3,
      FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmMono(fontSize: size, color: color, fontWeight: weight);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: cream,
    colorScheme: const ColorScheme.light(
      primary: yellow, secondary: yellow, surface: white, onPrimary: ink, error: red),
    textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: cream, surfaceTintColor: Colors.transparent, elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.bebasNeue(color: ink, fontSize: 24, letterSpacing: .05),
      iconTheme: const IconThemeData(color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: borderSide),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: borderSide),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: yellow3, width: bw)),
      hintStyle: mono(size: 13, color: txMuted),
      labelStyle: mono(size: 10, color: tx3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
      backgroundColor: ink, foregroundColor: yellow, minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: borderSide),
      textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w800), elevation: 0)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: ink, side: borderSide,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minimumSize: const Size(double.infinity, 48))),
    cardTheme: CardThemeData(color: white, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: borderSide)),
    dividerTheme: const DividerThemeData(color: ink, thickness: bw, space: 0),
    snackBarTheme: SnackBarThemeData(backgroundColor: ink,
      contentTextStyle: mono(size: 13, color: cream),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: yellow3)), behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(backgroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: borderSide)),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: ink, width: bw))),
  );
}

// ── StudBackground ────────────────────────────────────────────────────────────
class StudBackground extends StatelessWidget {
  final Color  color;
  final Widget child;
  const StudBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StudPainter(color),
    child: child,
  );
}

class _StudPainter extends CustomPainter {
  final Color bg;
  const _StudPainter(this.bg);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final p = Paint()..color = Colors.black.withOpacity(.09);
    const spacing = 16.0, radius = 2.5;
    for (double x = spacing / 2; x < size.width + spacing; x += spacing)
      for (double y = spacing / 2; y < size.height + spacing; y += spacing)
        canvas.drawCircle(Offset(x, y), radius, p);
  }

  @override
  bool shouldRepaint(covariant _StudPainter old) => old.bg != bg;
}
