import 'package:flutter/material.dart';

class C {
  static const Color g1     = Color(0xFF1A5C20);
  static const Color g2     = Color(0xFF2E7D32);
  static const Color gCard  = Color(0xFF1A4731);
  static const Color gLight = Color(0xFFE8F5E9);
  static const Color orange = Color(0xFFFF6B00);
  static const Color dark   = Color(0xFF1A1A1A);
  static const Color grey   = Color(0xFF757575);
  static const Color hint   = Color(0xFFBDBDBD);
  static const Color white  = Colors.white;
  static const Color bg     = Color(0xFFF5F7F5);

  static const Color adminBlue  = Color(0xFF1565C0);
  static const Color adminLight = Color(0xFFE3F2FD);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.g2, primary: C.g2),
    scaffoldBackgroundColor: C.white,
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.gLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.g2, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: const TextStyle(color: C.hint, fontSize: 14),
    ),
  );
}
