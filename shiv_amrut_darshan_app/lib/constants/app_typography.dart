import 'package:flutter/material.dart';

/// AppTypography configures fonts for Gujarati, Devanagari (Hindi),
/// and standard Noto Sans (English) using bundled asset fonts.
/// Fonts are bundled locally (assets/fonts/) so they work fully OFFLINE.
class AppTypography {
  AppTypography._();

  static TextStyle getStyle({
    required String languageCode,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double height = 1.5,
    TextDecoration? decoration,
  }) {
    final fontFamily = _fontFamilyFor(languageCode);
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  /// Returns the bundled font family name based on language code.
  static String _fontFamilyFor(String languageCode) {
    switch (languageCode) {
      case 'gu':
        return 'NotoSansGujarati';
      case 'hi':
        return 'NotoSansDevanagari';
      case 'en':
      default:
        return 'NotoSans';
    }
  }

  static TextTheme buildTextTheme(String languageCode, TextTheme base) {
    return base.copyWith(
      displayLarge: getStyle(
        languageCode: languageCode,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: getStyle(
        languageCode: languageCode,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: getStyle(
        languageCode: languageCode,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: getStyle(
        languageCode: languageCode,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: getStyle(
        languageCode: languageCode,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        height: 1.6,
      ),
      bodyMedium: getStyle(
        languageCode: languageCode,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
      ),
      labelLarge: getStyle(
        languageCode: languageCode,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
