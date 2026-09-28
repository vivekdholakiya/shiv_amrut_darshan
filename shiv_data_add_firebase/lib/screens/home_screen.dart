import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'settings_screen.dart';
import 'content_list_screen.dart';
import 'quotes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<Map<String, dynamic>?> _fetchData(BuildContext context) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return await _firebaseService.getBaseData(appProvider.currentLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Shiv Amrut Darshan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: FutureBuilder<Map<String, dynamic>?>(
            // We re-fetch when language changes
            future: _firebaseService.getBaseData(appProvider.currentLanguage),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text(
                    'Failed to load data. Please check your connection.',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                );
              }

              final data = snapshot.data!;
              
              // Map the m_id fields to sections
              final List<Map<String, dynamic>> categories = [
                {'id': 'id1', 'title': data['m_id1'] ?? 'Shiv Katha', 'icon': Icons.menu_book_rounded, 'hasStories': true},
                {'id': 'id2', 'title': data['m_id2'] ?? 'Shiv Puran', 'icon': Icons.library_books_rounded, 'hasStories': true},
                {'id': 'id3', 'title': data['m_id3'] ?? '12 Jyotirlingas', 'icon': Icons.place_rounded, 'hasStories': true},
                {'id': 'id4', 'title': data['m_id4'] ?? 'Shiv Mantras', 'icon': Icons.music_note_rounded, 'hasStories': true},
                {'id': 'id5', 'title': data['m_id5'] ?? 'Shiv Stotras', 'icon': Icons.library_music_rounded, 'hasStories': true},
                {'id': 'id7', 'title': data['m_id7'] ?? 'Quotes & Status', 'icon': Icons.format_quote_rounded, 'hasStories': false},
              ];

              return GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _CategoryCard(
                    title: cat['title'],
                    icon: cat['icon'],
                    onTap: () {
                      if (cat['id'] == 'id7') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuotesScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContentListScreen(
                              sectionId: cat['id'],
                              title: cat['title'],
                              hasStories: cat['hasStories'],
                            ),
                          ),
                        );
                      }
                    },
                  ).animate().fade(delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
