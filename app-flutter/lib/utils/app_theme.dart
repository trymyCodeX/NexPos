import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF1976D2);
  static const Color primaryBlueLight = Color(0xFFBBDEFB);

  static const Color green = Color(0xFF43A047);
  static const Color greenLight = Color(0xFFC8E6C9);

  static const Color orange = Color(0xFFFB8C00);
  static const Color orangeLight = Color(0xFFFFE0B2);

  static const Color red = Color(0xFFE53935);
  static const Color redLight = Color(0xFFFFCDD2);

  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray900 = Color(0xFF212121);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'diterima':
        return orange;
      case 'dicuci':
        return primaryBlue;
      case 'disetrika':
        return const Color(0xFF7B1FA2);
      case 'selesai':
        return green;
      case 'dibatalkan':
        return red;
      default:
        return gray500;
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'diterima':
        return orangeLight;
      case 'dicuci':
        return primaryBlueLight;
      case 'disetrika':
        return const Color(0xFFE1BEE7);
      case 'selesai':
        return greenLight;
      case 'dibatalkan':
        return redLight;
      default:
        return gray200;
    }
  }
}
