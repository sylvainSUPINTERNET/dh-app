import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F3EE);
  static const surface = Color(0xFFEEE8DF);
  static const textPrimary = Color(0xFF1C1410);
  static const textSecondary = Color(0xFF8C7B6B);
  static const accent = Color(0xFFC4956A);
  static const divider = Color(0xFFDDD5C8);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            height: 1.6,
            letterSpacing: 0.1,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
      );
}
