import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Accents (Monochrome White & Slate Accents)
  static const Color primary = Color(0xFFFFFFFF); // Crisp Pure White in Dark
  static const Color primaryLight = Color(0xFFF4F4F5); // Zinc 100
  static const Color primaryDark = Color(0xFFE4E4E7); // Zinc 200
  static const Color secondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color accent = Color(0xFFE4E4E7); // Silver White

  // Semantic Status Colors (Monochrome gradation)
  static const Color todo = Color(0xFF71717A); // Zinc 500 / Graphite
  static const Color inProgress = Color(0xFFD4D4D8); // Silver / Off-white
  static const Color inReview = Color(0xFFA1A1AA); // Zinc 400
  static const Color done = Color(0xFFFFFFFF); // Pure White
  static const Color statusDone = Color(0xFFFFFFFF); // Pure White

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981); // Emerald Green
  static const Color priorityMedium = Color(0xFFF59E0B); // Amber Gold
  static const Color priorityHigh = Color(0xFFF97316); // Sunset Orange
  static const Color priorityUrgent = Color(0xFFEF4444); // Crimson Red

  // Dark Theme Neutral Gradients & Surfaces (OLED Pitch Black & Obsidian)
  static const Color darkBg = Color(0xFF000000); // True OLED Pitch Black
  static const Color darkCard = Color(0xFF0D0D0E); // Deep Obsidian
  static const Color darkSurface = Color(0xFF141416); // Charcoal Surface
  static const Color darkBorder = Color(0xFF26262B); // Crisp Minimalist Border
  static const Color darkText = Color(0xFFFFFFFF); // Crisp White
  static const Color darkTextMuted = Color(0xFF8E8E93); // Muted Silver Gray

  // Light Theme Surfaces (Clean Paper White & Minimalist Charcoal)
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightText = Color(0xFF09090B);
  static const Color lightTextMuted = Color(0xFF71717A);

  // Semantic helpers
  static const Color warning = Color(0xFFD4D4D8);
  static const Color error = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFF0D0D0E);
  static const Color surfaceLight = Color(0xFF141416);
  static const Color border = Color(0xFF26262B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF8E8E93);
}


