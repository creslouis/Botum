import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryLight = Color(0xFFFF69B4);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color screenBackgroundDark = Color(0xFF000000);
  static const Color screenBackgroundLight = Color(0xFFFFFFFF);

  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnLight = Color(0xFF000000);

  static Color get primaryWithOpacity => primary.withOpacity(0.1);
  static Color get scaffoldBackground => white;

  static const List<Color> pinkGradient = [
    primary,
    primaryLight,
  ];
}
