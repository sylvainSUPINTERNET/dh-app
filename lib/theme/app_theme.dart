import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F3EE);
  static const surface = Color(0xFFEEE8DF);
  static const navigationSurface = Color(0xFFFFF8F4);
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
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.surface,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.surface,
      onSecondaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navigationSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
      overlayColor: WidgetStateProperty.all(
        AppColors.accent.withValues(alpha: 0.08),
      ),
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
