import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import 'reading_screen.dart';

class ContentListScreen extends StatefulWidget {
  final String sectionId;
  final String title;
  final bool hasStories;

  const ContentListScreen({
    super.key,
    required this.sectionId,
    required this.title,
    required this.hasStories,
  });

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic> _allTitles = {};
  List<MapEntry<String, dynamic>> _filteredTitles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final langCode = Provider.of<AppProvider>(context, listen: false).currentLanguage;
    final titles = await _firebaseService.getSectionData(langCode, widget.sectionId, 'titles');
    
    if (mounted) {
      setState(() {
        _allTitles = titles;
        _filteredTitles = titles.entries.toList()
          ..sort((a, b) => _compareKeys(a.key, b.key)); // Custom sort to handle "id1_2" vs "id1_10"
        _isLoading = false;
      });
    }
  }

  int _compareKeys(String a, String b) {
    // Keys are like "id1_1", "id1_2". We want to sort by the numeric part
    final aParts = a.split('_');
    final bParts = b.split('_');
    if (aParts.length > 1 && bParts.length > 1) {
      final aNum = int.tryParse(aParts[1]) ?? 0;
      final bNum = int.tryParse(bParts[1]) ?? 0;
      return aNum.compareTo(bNum);
    }
    return a.compareTo(b);
  }

  void _filterTitles(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTitles = _allTitles.entries.toList()..sort((a, b) => _compareKeys(a.key, b.key));
      } else {
        _filteredTitles = _allTitles.entries
            .where((entry) => entry.value.toString().toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) => _compareKeys(a.key, b.key));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: _filterTitles,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTitles.isEmpty
              ? Center(
                  child: Text(
                    'No content found.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _filteredTitles.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredTitles[index];
                    return _buildListItem(entry.key, entry.value.toString(), index);
                  },
                ),
    );
  }

  Widget _buildListItem(String itemKey, String itemTitle, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          itemTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF6B00)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadingScreen(
                sectionId: widget.sectionId,
                itemKey: itemKey,
                title: itemTitle,
                hasStories: widget.hasStories,
              ),
            ),
          );
        },
      ),
    ).animate().fade(delay: (30 * index).ms).slideX(begin: 0.1, end: 0);
  }
}
