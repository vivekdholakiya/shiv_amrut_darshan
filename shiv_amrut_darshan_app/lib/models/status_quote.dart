import 'package:cloud_firestore/cloud_firestore.dart';

/// StatusQuote represents a single Shiv devotional quote
/// fetched from Firestore at: /shivQuotes/{language}
/// where all quotes are stored as fields (id7_1, id7_2, ...) in a single document.
class StatusQuote {
  final String id;
  final String text;
  final String category;
  final String categoryId;
  final String language;
  final int order;

  const StatusQuote({
    required this.id,
    required this.text,
    this.category = '',
    required this.categoryId,
    required this.language,
    this.order = 0,
  });

  /// Safely parse a Firestore DocumentSnapshot into a StatusQuote.
  factory StatusQuote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StatusQuote(
      id: doc.id,
      text: data['text']?.toString().trim() ?? '',
      category: data['category']?.toString().trim() ?? '',
      categoryId: data['categoryId']?.toString().trim() ?? 'all',
      language: data['language']?.toString().trim() ?? 'gu',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory StatusQuote.fromJson(Map<String, dynamic> json) {
    return StatusQuote(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? 'all',
      language: json['language']?.toString() ?? 'gu',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'category': category,
        'categoryId': categoryId,
        'language': language,
        'order': order,
      };

  bool get isValid => text.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusQuote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          language == other.language;

  @override
  int get hashCode => id.hashCode ^ language.hashCode;
}
