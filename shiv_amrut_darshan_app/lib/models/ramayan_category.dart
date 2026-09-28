import 'package:flutter/material.dart';

/// ShivCategory (formerly RamayanCategory) model representing each of the
/// 6 main categories in the Shiv Amrut Darshan app.
/// The 'id' field matches the Firestore subcollection key under ShivAmrutDarshan/{lang}/.
class RamayanCategory {
  final String id;
  final String gu;
  final String hi;
  final String en;
  final IconData icon;
  final String imageAsset;

  const RamayanCategory({
    required this.id,
    required this.gu,
    required this.hi,
    required this.en,
    required this.icon,
    required this.imageAsset,
  });

  /// Helper getter to retrieve localized title based on language code.
  String getLocalizedTitle(String languageCode) {
    switch (languageCode) {
      case 'gu':
        return gu;
      case 'hi':
        return hi;
      case 'en':
      default:
        return en;
    }
  }

  /// The 6 primary categories matching Firestore subcollection IDs under ShivAmrutDarshan/{lang}/.
  static const List<RamayanCategory> categories = [
    RamayanCategory(
      id: 'id1',
      gu: 'શિવ કથા',
      hi: 'शिव कथा',
      en: 'Shiv Katha',
      icon: Icons.menu_book_rounded,
      imageAsset: 'assets/images/shiv_katha.png',
    ),
    RamayanCategory(
      id: 'id2',
      gu: 'શિવ પુરાણ',
      hi: 'शिव पुराण',
      en: 'Shiv Puran',
      icon: Icons.library_books_rounded,
      imageAsset: 'assets/images/shiv_puran.png',
    ),
    RamayanCategory(
      id: 'id3',
      gu: '12 જ્યોતિર્લિંગ',
      hi: '12 ज्योतिर्लिंग',
      en: '12 Jyotirlingas',
      icon: Icons.place_rounded,
      imageAsset: 'assets/images/jyotirlinga.png',
    ),
    RamayanCategory(
      id: 'id4',
      gu: 'શિવ મંત્ર',
      hi: 'शिव मंत्र',
      en: 'Shiv Mantras',
      icon: Icons.music_note_rounded,
      imageAsset: 'assets/images/shiv_mantra.png',
    ),
    RamayanCategory(
      id: 'id5',
      gu: 'શિવ સ્તોત્ર',
      hi: 'शिव स्तोत्र',
      en: 'Shiv Stotras',
      icon: Icons.library_music_rounded,
      imageAsset: 'assets/images/shiv_stotra.png',
    ),
  ];

  static RamayanCategory? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
