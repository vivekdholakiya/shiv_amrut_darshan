import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<String> _quotes = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    final langCode = Provider.of<AppProvider>(context, listen: false).currentLanguage;
    final quotesData = await _firebaseService.getQuotes(langCode);

    if (mounted) {
      setState(() {
        if (quotesData != null) {
          // Sort keys id7_1, id7_2 ... to display sequentially
          final entries = quotesData.entries.toList()
            ..sort((a, b) {
              final aNum = int.tryParse(a.key.split('_').last) ?? 0;
              final bNum = int.tryParse(b.key.split('_').last) ?? 0;
              return aNum.compareTo(bNum);
            });
          _quotes = entries.map((e) => e.value.toString()).toList();
        }
        _isLoading = false;
      });
    }
  }

  void _shareQuote() {
    if (_quotes.isNotEmpty) {
      Share.share('"${_quotes[_currentIndex]}"\n\n- Shiv Amrut Darshan App');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes & Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _quotes.isNotEmpty ? _shareQuote : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? const Center(child: Text('No quotes found.'))
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _quotes.length,
                  itemBuilder: (context, index) {
                    return _buildQuoteCard(_quotes[index]);
                  },
                ),
    );
  }

  Widget _buildQuoteCard(String quote) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B00).withValues(alpha: 0.1),
                const Color(0xFFFFB347).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.format_quote_rounded, size: 60, color: Color(0xFFFF6B00)),
              const SizedBox(height: 24),
              Text(
                quote,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                '${_currentIndex + 1} / ${_quotes.length}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}
