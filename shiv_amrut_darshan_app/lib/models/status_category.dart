import 'package:cloud_firestore/cloud_firestore.dart';

/// StatusCategory represents a quote category.
/// For Shiv Amrut Darshan, categories are synthesized locally since all
/// quotes are stored in a single flat document (no sub-categories in Firebase).
class StatusCategory {
  final String id;
  final String name;
  final String language;
  final String iconName;

  const StatusCategory({
    required this.id,
    required this.name,
    this.language = '',
    this.iconName = 'format_quote_rounded',
  });

  /// Safely parse a Firestore DocumentSnapshot into a StatusCategory.
  factory StatusCategory.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StatusCategory(
      id: doc.id,
      name: data['name']?.toString().trim() ?? doc.id,
      language: data['language']?.toString().trim() ?? 'gu',
      iconName: data['iconName']?.toString().trim() ?? 'format_quote_rounded',
    );
  }

  factory StatusCategory.fromJson(Map<String, dynamic> json) {
    return StatusCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      language: json['language']?.toString() ?? 'gu',
      iconName: json['iconName']?.toString() ?? 'format_quote_rounded',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'language': language,
        'iconName': iconName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
