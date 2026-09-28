import 'package:flutter/material.dart';

/// AppColors defines the Premium Devotional Blue visual palette for Shiv Amrut Darshan.
/// Inspired by divine skies, calm night meditation, holy waters of Ganga,
/// and subtle divine gold accents.
class AppColors {
  AppColors._();

  // ── 1. Light Theme Colors ──────────────────────────────────────────────────
  static const Color lightPrimary = Color(0xFF1565C0); // Primary Blue
  static const Color lightPrimaryDark = Color(0xFF0D47A1); // Primary Dark
  static const Color lightPrimaryLight = Color(0xFF42A5F5); // Primary Light
  static const Color lightSecondary = Color(0xFF1976D2); // Secondary Blue
  static const Color lightAccent = Color(0xFF29B6F6); // Accent Blue

  static const Color lightBackground = Color(0xFFF5F9FF); // Main Light Background
  static const Color lightSecondaryBackground = Color(0xFFEDF5FF);
  static const Color lightSurface = Color(0xFFFFFFFF); // Surface / Card

  static const Color lightTextPrimary = Color(0xFF102A43); // Primary Text
  static const Color lightTextSecondary = Color(0xFF486581); // Secondary Text
  static const Color lightTextMuted = Color(0xFF829AB1); // Muted Text

  static const Color lightBorder = Color(0xFFD6E4F0); // Border
  static const Color lightDivider = Color(0xFFE3EDF7); // Divider

  // ── 2. Dark Theme Colors ───────────────────────────────────────────────────
  static const Color darkPrimary = Color(0xFF64B5F6); // Primary Blue for Dark
  static const Color darkPrimaryDark = Color(0xFF42A5F5); // Primary Pressed
  static const Color darkAccent = Color(0xFF29B6F6); // Accent Blue

  static const Color darkBackground = Color(0xFF071525); // Main Dark Background
  static const Color darkSecondaryBackground = Color(0xFF0B1E33);
  static const Color darkSurface = Color(0xFF102A43); // Dark Surface / Card
  static const Color darkElevatedSurface = Color(0xFF163A5C); // Elevated Dark Surface

  static const Color darkTextPrimary = Color(0xFFF5F9FF); // Primary Dark Text
  static const Color darkTextSecondary = Color(0xFFB8CCE0); // Secondary Dark Text
  static const Color darkTextMuted = Color(0xFF89A6BF); // Muted Dark Text

  static const Color darkBorder = Color(0xFF244866); // Dark Border
  static const Color darkDivider = Color(0xFF1D3B56); // Dark Divider

  // ── 3. Devotional Accent ───────────────────────────────────────────────────
  static const Color divineGold = Color(0xFFD4AF37); // Divine Gold (Light)
  static const Color darkDivineGold = Color(0xFFE6C766); // Divine Gold (Dark)

  // ── 4. Backwards-compatible Theme Aliases ──────────────────────────────────
  static const Color deepSaffron = lightPrimary;
  static const Color brightSaffron = darkPrimary;
  static const Color warmGold = divineGold;
  static const Color accentGold = darkDivineGold;
  static const Color mutedMaroon = lightPrimaryDark;
  static const Color sacredRed = lightSecondary;

  static const Color parchmentLight = lightBackground;
  static const Color parchmentCard = lightSurface;
  static const Color parchmentBorder = lightBorder;
  static const Color parchmentBorderHover = lightPrimary;
  static const Color textDarkBrown = lightTextPrimary;
  static const Color textMutedBrown = lightTextSecondary;

  static const Color darkCard = darkSurface;
  static const Color darkBorderHover = darkPrimary;
  static const Color textLightIvory = darkTextPrimary;
  static const Color textMutedIvory = darkTextSecondary;

  // Accents & Functional
  static const Color favoriteRed = Color(0xFFE74C3C);
  static const Color errorRed = Color(0xFFC0392B);
  static const Color successGreen = Color(0xFF27AE60);

  static const Color shimmerBaseLight = lightBorder;
  static const Color shimmerHighlightLight = lightBackground;
  static const Color shimmerBaseDark = darkSurface;
  static const Color shimmerHighlightDark = darkElevatedSurface;

  // Gradients
  static const LinearGradient saffronGoldGradient = LinearGradient(
    colors: [lightPrimaryDark, lightSecondary, lightPrimaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient parchmentGradientLight = LinearGradient(
    colors: [lightBackground, lightSecondaryBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient parchmentGradientDark = LinearGradient(
    colors: [darkBackground, Color(0xFF0B2D4D), Color(0xFF123E63)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
