import 'package:flutter/material.dart';

class AppTheme {
  // Distinct accent per app so testers can tell them apart at a glance;
  // both share the same warm, friendly pet-care palette otherwise.
  static ThemeData userApp() => _base(const Color(0xFFFF7A59)); // coral
  static ThemeData providerApp() => _base(const Color(0xFF2E7D6B)); // teal

  static ThemeData _base(Color seed) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      scaffoldBackgroundColor: const Color(0xFFFAF9F6),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
