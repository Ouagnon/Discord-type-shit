import 'package:flutter/material.dart';

/// Charte sombre de l'application (l'apparence des maquettes n'étant pas
/// contractuelle, ces valeurs reprennent l'esprit « Discord »).
class DtsTheme {
  DtsTheme._();

  static const brand = Color(0xFF5865F2);
  static const background = Color(0xFF1e1f22);
  static const surface = Color(0xFF2b2d31);
  static const surfaceHigh = Color(0xFF313338);

  static ThemeData dark() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
      surface: surface,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceHigh,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      dividerColor: const Color(0xFF3f4147),
      listTileTheme: const ListTileThemeData(iconColor: Color(0xFF949ba4)),
    );
  }
}
