import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFFC107);
  static const Color danger = Color(0xFFEF4444);
  static const Color surface = Color(0xFFF4F9F5);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE8F3EB);

  static Color get textColor => const Color(0xFF1E272C);
  static Color get textMuted => const Color(0xFF64748B);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: primary,
        scaffoldBackgroundColor: surface,
        cardColor: card,
        dividerColor: border,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: card,
          onSurface: Color(0xFF1E272C),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF1E272C),
        ),
      );

  static ThemeData get dark => light;
}
