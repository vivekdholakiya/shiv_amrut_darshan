import 'dart:math';
import '../models/status_item.dart';
import '../models/status_quote.dart';

/// StatusRandomizer produces a shuffled list of [StatusItem] objects
/// by pairing quotes with background images.
///
/// Rules:
///  - Never crashes if images or quotes list is empty.
///  - Never hardcodes image count.
///  - Uses modulo cycling so images repeat evenly if fewer than quotes.
///  - Fisher-Yates shuffle ensures no consecutive duplicates.
///  - All randomization is isolated here — no Random() calls in UI widgets.
class StatusRandomizer {
  final _random = Random();

  /// Generates a shuffled list of [StatusItem] from available quotes + images.
  /// If [count] is null or 0, generates for ALL quotes in the list (e.g. all 200 quotes).
  List<StatusItem> generateStatusItems({
    required List<StatusQuote> quotes,
    required List<String> imageUrls,
    int? count,
  }) {
    if (quotes.isEmpty) return [];

    final shuffledQuotes = List<StatusQuote>.from(quotes);
    _fisherYatesShuffle(shuffledQuotes);

    final targetCount = (count == null || count <= 0) ? quotes.length : count;
    final actualCount = targetCount.clamp(1, quotes.length * 3);

    final hasImages = imageUrls.isNotEmpty;
    final shuffledImages = hasImages ? List<String>.from(imageUrls) : <String>[];

    if (hasImages) {
      _fisherYatesShuffle(shuffledImages);
    }

    final items = <StatusItem>[];

    for (int i = 0; i < actualCount; i++) {
      final quote = shuffledQuotes[i % shuffledQuotes.length];
      final imageUrl = hasImages ? shuffledImages[i % shuffledImages.length] : '';
      items.add(StatusItem(quote: quote, imageUrl: imageUrl));
    }

    return items;
  }

  /// Shuffles [list] in-place using Fisher-Yates algorithm.
  void _fisherYatesShuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// Generates a fresh single [StatusItem] from available data,
  /// used when swiping to the next status in the viewer.
  StatusItem? nextRandom({
    required List<StatusQuote> quotes,
    required List<String> imageUrls,
    StatusItem? excluding,
  }) {
    if (quotes.isEmpty) return null;

    final quotesCopy = List<StatusQuote>.from(quotes);
    _fisherYatesShuffle(quotesCopy);

    final hasImages = imageUrls.isNotEmpty;
    final imagesCopy = hasImages ? List<String>.from(imageUrls) : <String>[];
    if (hasImages) {
      _fisherYatesShuffle(imagesCopy);
    }

    // Try to pick a different quote than the excluded one
    StatusQuote chosenQuote = quotesCopy.first;
    if (excluding != null && quotesCopy.length > 1) {
      chosenQuote = quotesCopy.firstWhere(
        (q) => q.id != excluding.quote.id,
        orElse: () => quotesCopy.first,
      );
    }

    // Try to pick a different image
    String chosenImage = hasImages ? imagesCopy.first : '';
    if (hasImages && excluding != null && imagesCopy.length > 1) {
      chosenImage = imagesCopy.firstWhere(
        (url) => url != excluding.imageUrl,
        orElse: () => imagesCopy.first,
      );
    }

    return StatusItem(quote: chosenQuote, imageUrl: chosenImage);
  }
}
