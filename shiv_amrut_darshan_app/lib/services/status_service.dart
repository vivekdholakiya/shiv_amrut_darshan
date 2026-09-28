import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/status_category.dart';
import '../models/status_quote.dart';

/// StatusService reads devotional quote data from Firestore.
///
/// Paths (Shiv Amrut Darshan):
///   Quotes → /shivQuotes/{language}  (single document, fields: id7_1, id7_2, ... id7_200)
///
/// Note: The old Ramayan app used sub-collections for quotes and categories.
/// This app stores all 200 quotes as fields in a SINGLE document per language.
class StatusService {
  final FirebaseFirestore _firestore;

  StatusService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── In-memory caches ──────────────────────────────────────────────────────
  final Map<String, List<StatusCategory>> _categoryCache = {};
  final Map<String, List<StatusQuote>> _quotesCache = {};
  List<String>? _imageUrlsCache;

  void clearCache() {
    _categoryCache.clear();
    _quotesCache.clear();
    _imageUrlsCache = null;
  }

  // ── Categories ────────────────────────────────────────────────────────────
  /// Returns a single default "All Quotes" category since Shiv Amrut Darshan
  /// stores all quotes in one flat document without sub-categories.
  Future<List<StatusCategory>> fetchCategories(
    String language, {
    bool forceRefresh = false,
  }) async {
    // Return a single placeholder category for the UI
    return [
      StatusCategory(
        id: 'all',
        name: language == 'gu'
            ? 'બધા અવતરણ'
            : language == 'hi'
                ? 'सभी उद्धरण'
                : 'All Quotes',
        iconName: 'format_quote_rounded',
      ),
    ];
  }

  // ── Quotes ────────────────────────────────────────────────────────────────
  /// Fetches all quotes for the given language from /shivQuotes/{language}.
  /// The document contains fields like id7_1, id7_2, ..., id7_200.
  Future<List<StatusQuote>> fetchQuotes(
    String language, {
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = language;

    if (!forceRefresh && _quotesCache.containsKey(cacheKey)) {
      return _quotesCache[cacheKey]!;
    }

    Future<DocumentSnapshot<Map<String, dynamic>>> fetchDoc(Source source) {
      return _firestore
          .collection('shivQuotes')
          .doc(language)
          .get(GetOptions(source: source));
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await fetchDoc(Source.serverAndCache);
      } catch (_) {
        doc = await fetchDoc(Source.cache);
      }

      if (!doc.exists || doc.data() == null) {
        if (kDebugMode) print('[StatusService] No quotes doc for language: $language');
        return [];
      }

      final data = doc.data()!;

      // Sort keys numerically: id7_1, id7_2, ..., id7_200
      final sortedKeys = data.keys.toList()
        ..sort((a, b) {
          final aNum = int.tryParse(a.split('_').last) ?? 0;
          final bNum = int.tryParse(b.split('_').last) ?? 0;
          return aNum.compareTo(bNum);
        });

      final quotes = sortedKeys.asMap().entries.map((entry) {
        final index = entry.key;
        final key = entry.value;
        final text = data[key]?.toString().trim() ?? '';
        return StatusQuote(
          id: key,
          text: text,
          categoryId: 'all',
          language: language,
          order: index,
        );
      }).where((q) => q.isValid).toList();

      _quotesCache[cacheKey] = quotes;
      if (kDebugMode) {
        print('[StatusService] Loaded ${quotes.length} quotes for $language');
      }
      return quotes;
    } catch (e) {
      if (kDebugMode) print('[StatusService] fetchQuotes error: $e');
      return [];
    }
  }

  // ── Image URLs ────────────────────────────────────────────────────────────
  /// Fetches background image URLs from /shivQuotes/imageUrl document (if any).
  Future<List<String>> fetchImageUrls({bool forceRefresh = false}) async {
    if (!forceRefresh && _imageUrlsCache != null) {
      return _imageUrlsCache!;
    }

    try {
      final doc = await _firestore
          .collection('shivQuotes')
          .doc('imageUrl')
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists || doc.data() == null) {
        if (kDebugMode) print('[StatusService] imageUrl document not found');
        _imageUrlsCache = [];
        return [];
      }

      final urls = doc
          .data()!
          .values
          .map((v) => v?.toString().trim() ?? '')
          .where((url) => url.isNotEmpty && url.startsWith('http'))
          .toList();

      _imageUrlsCache = urls;
      if (kDebugMode) print('[StatusService] Loaded ${urls.length} image URLs');
      return urls;
    } catch (e) {
      if (kDebugMode) print('[StatusService] fetchImageUrls error: $e');
      _imageUrlsCache = [];
      return [];
    }
  }
}
