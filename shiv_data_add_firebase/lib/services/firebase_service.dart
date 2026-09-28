import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService() {
    // Note: Offline persistence is enabled by default on Android/iOS in the latest SDKs,
    // but configuring cache explicitly is good practice.
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Fetches the base document (menu labels and metadata) for a given language
  Future<Map<String, dynamic>?> getBaseData(String langCode) async {
    try {
      final docSnapshot = await _firestore
          .collection('ShivAmrutDarshan')
          .doc(langCode)
          .get(const GetOptions(source: Source.serverAndCache));
      return docSnapshot.data();
    } catch (e) {
      // Fallback to cache if offline
      final docSnapshot = await _firestore
          .collection('ShivAmrutDarshan')
          .doc(langCode)
          .get(const GetOptions(source: Source.cache));
      return docSnapshot.data();
    }
  }

  /// Fetches all data (titles or stories) for a specific section by merging chunked documents
  Future<Map<String, dynamic>> getSectionData(
      String langCode, String sectionId, String type) async {
    // Note: The data might be in a single document 'titles'/'stories'
    // or spread across chunks like 'titles_chunk_0', 'titles_chunk_1'.
    
    Future<QuerySnapshot> fetchQuery(Source source) {
      return _firestore
          .collection('ShivAmrutDarshan')
          .doc(langCode)
          .collection(sectionId)
          // Fetch documents where ID starts with the type (e.g. 'titles' or 'titles_chunk_')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: type)
          .where(FieldPath.documentId, isLessThan: '${type}z')
          .get(GetOptions(source: source));
    }

    QuerySnapshot querySnapshot;
    try {
      querySnapshot = await fetchQuery(Source.serverAndCache);
    } catch (e) {
      querySnapshot = await fetchQuery(Source.cache);
    }

    final Map<String, dynamic> mergedData = {};
    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        mergedData.addAll(data);
      }
    }
    return mergedData;
  }

  /// Fetches quotes directly from the shivQuotes collection
  Future<Map<String, dynamic>?> getQuotes(String langCode) async {
    try {
      final docSnapshot = await _firestore
          .collection('shivQuotes')
          .doc(langCode)
          .get(const GetOptions(source: Source.serverAndCache));
      return docSnapshot.data();
    } catch (e) {
      final docSnapshot = await _firestore
          .collection('shivQuotes')
          .doc(langCode)
          .get(const GetOptions(source: Source.cache));
      return docSnapshot.data();
    }
  }
}
