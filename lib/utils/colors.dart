import 'package:flutter/material.dart';

class AppColors {
  // Core app colors
  static const Color primary = Color(0xFF4CAF50); // Green
  static const Color secondary = Color(0xFF020618); // Dark mode color
  static const Color accent = Color(0xFF81C784); // Light green
  static const Color backgroundLight = Color(0xFFE5E6EA); // Light background
  static const Color backgroundDark = Color(0xFF364052); // Dark background
  static const Color textLight = Color(0xFF000000);
  static const Color textDark = Color(0xFFFFFFFF);

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Tailwind gray scale
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF2F5F6);
  static const Color gray200 = Color(0xFFE4E6EB);
  static const Color gray300 = Color(0xFFD1D5DC);
  static const Color gray400 = Color(0xFF99A1AF);
  static const Color gray500 = Color(0xFF6B7283);
  static const Color gray600 = Color(0xFF4B5564);
  static const Color gray700 = Color(0xFF374053);
  static const Color gray800 = Color(0xFF1F2839);
  static const Color gray900 = Color(0xFF111928);
  static const Color gray950 = Color(0xFF020713);

  // Tailwind colors
  static const Color green500 = Color(0xFF01C951);
  static const Color green700 = Color(0xFF018336);

  static const Color red500 = Color(0xFFFB2D37);
  static const Color red700 = Color(0xFFC00107);

  static const Color blue500 = Color(0xFF2B7FFF);
  static const Color blue700 = Color(0xFF1446E7);

  static const Color yellow500 = Color(0xFFFACC15); // Tailwind Yellow-500
  static const Color yellow700 = Color(0xFFEAB308); // Tailwind Yellow-700

  static const Color orange500 = Color(0xFFFB923C); // Tailwind Orange-500
  static const Color orange700 = Color(0xFFEA580C); // Tailwind Orange-700

  static const Color purple500 = Color(0xFFA855F7); // Tailwind Purple-500
  static const Color purple700 = Color(0xFF7E22CE); // Tailwind Purple-700

  static const Color teal500 = Color(0xFF14B8A6); // Tailwind Teal-500
  static const Color teal700 = Color(0xFF0D9488); // Tailwind Teal-700

  // Themed color helper
  static Color themedColor(BuildContext context, Color light, Color dark) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
