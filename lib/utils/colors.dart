import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4CAF50); // Green
  static const Color secondary = Color(0xFF020618); // Dark mode color
  static const Color accent = Color(0xFF81C784); // Light green
  static const Color backgroundLight = Color(0xFFE5E6EA); // White for light mode
  static const Color backgroundDark = Color(0xFF364052); // Dark mode background
  static const Color textLight = Color(0xFF000000); // Black text for light mode
  static const Color textDark = Color(0xFFFFFFFF); // White text for dark mode

  static const Color white = Colors.white;
  static const Color gray50 = Color(0xFFF9FAFB); // Tailwind Gray-100
  static const Color gray100 = Color(0xFFF2F5F6); // Tailwind Gray-100
  static const Color gray200 = Color(0xFFE4E6EB); // Tailwind Gray-200
  static const Color gray300 = Color(0xFFD1D5DC); // Tailwind Gray-300
  static const Color gray400 = Color(0xFF99A1AF); // Tailwind Gray-400
  static const Color gray500 = Color(0xFF6B7283); // Tailwind Gray-500
  static const Color gray600 = Color(0xFF4B5564); // Tailwind Gray-600
  static const Color gray700 = Color(0xFF374053); // Tailwind Gray-700
  static const Color gray800 = Color(0xFF1F2839); // Tailwind Gray-800
  static const Color gray900 = Color(0xFF111928); // Tailwind Gray-900
  static const Color gray950 = Color(0xFF020713); // Tailwind Gray-900

  static const Color green500 = Color(0xFF01C951); // Tailwind Green-500
  static const Color green700 = Color(0xFF018336); // Tailwind Green-700

  static const Color red500 = Color(0xFFFB2D37); // Tailwind Red-500
  static const Color red700 = Color(0xFFC00107); // Tailwind Red-700

  static const Color blue500 = Color(0xFF2B7FFF); // Tailwind Blue-500
  static const Color blue700 = Color(0xFF1446E7); // Tailwind Blue-700

  static Color themedColor(BuildContext context, Color light, Color dark) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
