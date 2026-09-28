import 'package:flutter/material.dart';

String formatDescription(String text) {
  return text
      .replaceAll(r'/n/n', '\n\n')
      .replaceAll(r'/n', '\n')
      .replaceAll(r'\n\n', '\n\n')
      .replaceAll("—", "-")
      .trim();
}

/// Removes markdown tags like ** for plain text displays (previews/shares).
String cleanMarkdownText(String text) {
  return formatDescription(text).replaceAll('**', '');
}

/// Parses text containing **bold** tags into a list of [InlineSpan]s for RichText / SelectableText.rich.
List<InlineSpan> parseMarkdownSpans(
  String text, {
  required TextStyle baseStyle,
  Color? boldColor,
}) {
  final cleanText = formatDescription(text);
  final parts = cleanText.split('**');
  final spans = <InlineSpan>[];

  for (int i = 0; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;

    // Odd indices are between ** and ** -> Bold text!
    if (i % 2 == 1) {
      spans.add(
        TextSpan(
          text: part,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: boldColor ?? baseStyle.color,
          ),
        ),
      );
    } else {
      spans.add(
        TextSpan(
          text: part,
          style: baseStyle,
        ),
      );
    }
  }

  return spans;
}

String appUrl =
    'https://play.google.com/store/apps/details?id=com.vivek.valmiki.ramayan';