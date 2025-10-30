import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5C233A);
  static const Color primaryDark = Color(0xFF3B1323);
  static const Color primaryLight = Color(0xFF8A3B62);
  static const Color surface = Color(0xFFF7F6F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF8A8A8A);
}

class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6)),
  ];
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorSchemeSeed: AppColors.primary);
  final scheme = base.colorScheme.copyWith(surface: const Color(0xFFF0EDF1));
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFD0CDD2),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x33000000)),
      ),
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final scheme = base.colorScheme.copyWith(
    primary: AppColors.primaryLight,
    secondary: AppColors.primaryLight,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF1E1C1F),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class AppCategories {
  static const it = 'IT-курсы';
  static const languages = 'Иностранные языки';
  static const modeling = '3Д/2Д моделирование';
  static const other = 'Остальные курсы';
  static const all = [it, languages, modeling, other];
}
