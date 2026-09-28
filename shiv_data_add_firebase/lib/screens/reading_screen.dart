import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';

class ReadingScreen extends StatefulWidget {
  final String sectionId;
  final String itemKey;
  final String title;
  final bool hasStories;

  const ReadingScreen({
    super.key,
    required this.sectionId,
    required this.itemKey,
    required this.title,
    required this.hasStories,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _content = '';
  bool _isLoading = true;
  double _fontSize = 18.0;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    if (!widget.hasStories) {
      setState(() {
        _content = widget.title; // If no story, title is the content (like quotes)
        _isLoading = false;
      });
      return;
    }

    final langCode = Provider.of<AppProvider>(context, listen: false).currentLanguage;
    final storiesData = await _firebaseService.getSectionData(langCode, widget.sectionId, 'stories');

    setState(() {
      _content = storiesData[widget.itemKey] ?? 'Content not available.';
      _isLoading = false;
    });
  }

  void _shareContent() {
    Share.share('*${widget.title}*\n\n$_content\n\n- Shiv Amrut Darshan App');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () {
              setState(() {
                if (_fontSize > 12) _fontSize -= 2;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () {
              setState(() {
                if (_fontSize < 36) _fontSize += 2;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _content.isNotEmpty && !_isLoading ? _shareContent : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                _content,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.6,
                ),
              ),
            ),
    );
  }
}
