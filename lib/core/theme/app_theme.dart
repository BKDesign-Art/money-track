import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1FAE66);
  static const primaryLight = Color(0xFFE3F5EC);
  static const background = Color(0xFFF7F9F8);
  static const splashBackground = Color(0xFF0E1A15);
  static const expense = Color(0xFFE53E3E);
  static const expenseLight = Color(0xFFFCE8E8);
  static const income = Color(0xFF1FAE66);
  static const warning = Color(0xFFF5A623);
  static const warningLight = Color(0xFFFDF0DC);
  static const textPrimary = Color(0xFF1A1D1E);
  static const textSecondary = Color(0xFF8A9199);
}

class AppRadius {
  static const card = 22.0;
  static const chip = 30.0;
}

// Une seule ombre douce, réutilisée partout, pour un rendu cohérent
class AppDecorations {
  static BoxDecoration softCard({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primaryLight,
        surfaceTintColor: Colors.transparent,
        height: 66,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}