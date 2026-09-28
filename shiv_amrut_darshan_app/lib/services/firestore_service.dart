import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ramayan_item.dart';

/// FirestoreService provides read-only access to ShivAmrutDarshan content
/// stored in Firebase Firestore at path: ShivAmrutDarshan/{language}/{categoryId}.
///
/// Data structure (uploaded by the Upload screen):
///   ShivAmrutDarshan/{language}/{categoryId}/titles        → { id1_1: "Title", ... }
///   ShivAmrutDarshan/{language}/{categoryId}/stories       → { id1_1: "Story text...", ... }
///   ShivAmrutDarshan/{language}/{categoryId}/titles_chunk_0 → overflow chunk if data > 100 fields
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// In-memory session cache. Key format: "{language}_{categoryId}"
  final Map<String, List<shivItem>> _categoryCache = {};

  void clearCache([String? cacheKey]) {
    if (cacheKey != null) {
      _categoryCache.remove(cacheKey);
    } else {
      _categoryCache.clear();
    }
  }

  /// Fetches ALL documents in the subcollection and groups them by type prefix.
  /// This avoids range queries that require composite indexes.
  Future<Map<String, Map<String, dynamic>>> _fetchAllSubcollectionDocs(
    String language,
    String categoryId, {
    required Source source,
  }) async {
    final querySnapshot = await _firestore
        .collection('ShivAmrutDarshan')
        .doc(language)
        .collection(categoryId)
        .get(GetOptions(source: source));

    // Group documents by their type prefix: "titles" vs "stories"
    final Map<String, Map<String, dynamic>> groups = {
      'titles': {},
      'stories': {},
    };

    for (final doc in querySnapshot.docs) {
      final docId = doc.id;
      final data = doc.data();

      if (docId.startsWith('titles')) {
        groups['titles']!.addAll(data);
      } else if (docId.startsWith('stories')) {
        groups['stories']!.addAll(data);
      }
    }

    return groups;
  }

  /// Fetches items for a specific category and language.
  /// Reads ALL docs in the subcollection then groups by titles/stories prefix.
  Future<List<shivItem>> getCategoryItems(
    String language,
    String categoryId, {
    bool forceRefresh = false,
    int? limit,
    DocumentSnapshot? lastDocument,
  }) async {
    final cacheKey = '${language}_$categoryId';

    if (!forceRefresh &&
        lastDocument == null &&
        _categoryCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        print('[ShivFirestore] Returning cached items for: $cacheKey');
      }
      return _categoryCache[cacheKey]!;
    }

    try {
      return await _fetchAndMergeItems(
          language, categoryId, Source.serverAndCache, cacheKey);
    } catch (e) {
      if (kDebugMode) {
        print('[ShivFirestore] Server fetch failed for $cacheKey → cache: $e');
      }
      try {
        return await _fetchAndMergeItems(
            language, categoryId, Source.cache, cacheKey);
      } catch (e2) {
        if (kDebugMode) {
          print('[ShivFirestore] Cache fetch also failed for $cacheKey: $e2');
        }
        return [];
      }
    }
  }

  Future<List<shivItem>> _fetchAndMergeItems(
    String language,
    String categoryId,
    Source source,
    String cacheKey,
  ) async {
    final groups = await _fetchAllSubcollectionDocs(
        language, categoryId, source: source);

    final titlesMap = groups['titles']!;
    final storiesMap = groups['stories']!;

    if (titlesMap.isEmpty) return [];

    // Sort keys numerically: id1_1, id1_2, ..., id1_10 (not lexicographic)
    final sortedKeys = titlesMap.keys.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.split('_').last) ?? 0;
        final bNum = int.tryParse(b.split('_').last) ?? 0;
        return aNum.compareTo(bNum);
      });

    final items = sortedKeys.map((key) {
      return shivItem(
        id: key,
        title: titlesMap[key]?.toString().trim() ?? key,
        description: storiesMap[key]?.toString().trim() ?? '',
        language: language,
        category: categoryId,
      );
    }).toList();

    _categoryCache[cacheKey] = items;
    if (kDebugMode) {
      print('[ShivFirestore] Loaded ${items.length} items for $cacheKey');
    }
    return items;
  }

  /// Fetches a single item from cache or Firestore.
  Future<shivItem?> getItem(
    String language,
    String categoryId,
    String itemId,
  ) async {
    final cacheKey = '${language}_$categoryId';

    if (_categoryCache.containsKey(cacheKey)) {
      final found = _categoryCache[cacheKey]!.where((i) => i.id == itemId);
      if (found.isNotEmpty) return found.first;
    }

    final items = await getCategoryItems(language, categoryId);
    return items.where((item) => item.id == itemId).firstOrNull;
  }
}
