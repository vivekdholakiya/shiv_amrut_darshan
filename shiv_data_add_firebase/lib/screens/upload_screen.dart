import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Progress tracking
  bool _isUploading = false;
  String _statusMessage = '';
  double _progress = 0.0;
  int _totalSteps = 0;
  int _completedSteps = 0;

  // Per-language status
  final Map<String, UploadStatus> _languageStatus = {
    'en': UploadStatus.idle,
    'gu': UploadStatus.idle,
    'hi': UploadStatus.idle,
  };

  final Map<String, String> _languageLabels = {
    'en': 'English',
    'gu': 'Gujarati',
    'hi': 'Hindi',
  };

  final Map<String, String> _languageFiles = {
    'en': 'assets/data_english.json',
    'gu': 'assets/data_gujrati.json',
    'hi': 'assets/data_hindi.json',
  };

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startUpload() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
      _progress = 0.0;
      _completedSteps = 0;
      _statusMessage = 'Starting upload...';
      for (final key in _languageStatus.keys) {
        _languageStatus[key] = UploadStatus.idle;
      }
    });

    try {
      // Count total sections across all languages
      // Each language has: m_ids(7) + id1(50) + id1_story(50) + id2(7) + id2_story(7) +
      //                    id3(12) + id3_story(12) + id4(5) + id4_story(5) +
      //                    id5(16) + id5_story(16) + id7(200) = ~387 per language, ~1161 total
      // We batch upload per document section.
      // Steps = 3 languages x 12 sections = 36 batches (approx)
      _totalSteps = 36;

      for (final langCode in ['en', 'gu', 'hi']) {
        setState(() {
          _languageStatus[langCode] = UploadStatus.uploading;
          _statusMessage =
              'Uploading ${_languageLabels[langCode]} data...';
        });

        final String jsonString = await rootBundle
            .loadString(_languageFiles[langCode]!);
        final Map<String, dynamic> jsonData =
            json.decode(jsonString) as Map<String, dynamic>;

        await _uploadLanguageData(langCode, jsonData);

        setState(() {
          _languageStatus[langCode] = UploadStatus.done;
        });
      }

      setState(() {
        _isUploading = false;
        _progress = 1.0;
        _statusMessage = '✅ All data uploaded successfully!';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = '❌ Error: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadLanguageData(
    String langCode,
    Map<String, dynamic> data,
  ) async {
    // ----------------------------------------------------------------
    // Firestore structure:
    //   ShivAmrutDarshan (collection)
    //     └── {langCode}  (document)   ← stores m_id1..m_id7 + data: count
    //           └── id1   (sub-collection)
    //                 └── titles (document) ← {id1_1: "...", id1_2: "..."}
    //                 └── stories (document) ← {id1_1: "...", id1_2: "..."}
    //           └── id2, id3 … (same pattern)
    //           └── id7   (sub-collection)
    //                 └── quotes (document) ← {id7_1: "...", …}
    // ----------------------------------------------------------------

    final docRef = _firestore
        .collection('ShivAmrutDarshan')
        .doc(langCode);

    // Build the base document with menu labels and metadata
    final Map<String, dynamic> baseDocData = {
      'm_id1': data['m_id1'],
      'm_id2': data['m_id2'],
      'm_id3': data['m_id3'],
      'm_id4': data['m_id4'],
      'm_id5': data['m_id5'],
      'm_id6': data['m_id6'],
      'm_id7': data['m_id7'],
      'data': 8, // total sections count as shown in original DB screenshot
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(baseDocData, SetOptions(merge: true));

    // Create new collection for quotes directly
    final quotesData = data['id7'] as Map<String, dynamic>?;
    if (quotesData != null) {
      await _firestore
          .collection('shivQuotes')
          .doc(langCode)
          .set(quotesData, SetOptions(merge: true));
    }

    // Upload each section as a sub-collection document
    final sections = [
      _SectionConfig('id1', 'id1_story'),
      _SectionConfig('id2', 'id2_story'),
      _SectionConfig('id3', 'id3_story'),
      _SectionConfig('id4', 'id4_story'),
      _SectionConfig('id5', 'id5_story'),
      _SectionConfig('id7', null), // quotes - no separate story
    ];

    for (final section in sections) {
      final titlesData = data[section.titlesKey] as Map<String, dynamic>?;
      if (titlesData != null) {
        // Firestore documents have a 1MB limit. For very large data, split into chunks.
        await _uploadChunked(
          docRef.collection(section.titlesKey).doc('titles'),
          titlesData,
        );
      }

      if (section.storiesKey != null) {
        final storiesData =
            data[section.storiesKey!] as Map<String, dynamic>?;
        if (storiesData != null) {
          await _uploadChunked(
            docRef.collection(section.titlesKey).doc('stories'),
            storiesData,
          );
        }
      }

      setState(() {
        _completedSteps++;
        _progress = _completedSteps / _totalSteps;
        _statusMessage =
            'Uploading ${_languageLabels[langCode]} → ${section.titlesKey}...';
      });
    }
  }

  /// Splits large maps into ≤100-field chunks to stay within Firestore limits
  Future<void> _uploadChunked(
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) async {
    // Split data into chunks of 100 entries
    final keys = data.keys.toList();
    const chunkSize = 100;

    if (keys.length <= chunkSize) {
      // Small enough to upload in one shot
      await docRef.set(data, SetOptions(merge: true));
    } else {
      // Use batch writes for larger data sets
      final batch = _firestore.batch();
      // Store each chunk as a separate document: doc_0, doc_1, etc.
      for (int i = 0; i < keys.length; i += chunkSize) {
        final end = (i + chunkSize < keys.length) ? i + chunkSize : keys.length;
        final chunkKeys = keys.sublist(i, end);
        final chunkData = <String, dynamic>{};
        for (final k in chunkKeys) {
          chunkData[k] = data[k];
        }
        final chunkRef = docRef.parent.doc(
          '${docRef.id}_chunk_${i ~/ chunkSize}',
        );
        batch.set(chunkRef, chunkData, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Color _statusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.idle:
        return Colors.grey.shade600;
      case UploadStatus.uploading:
        return const Color(0xFFFF6B00);
      case UploadStatus.done:
        return const Color(0xFF4CAF50);
      case UploadStatus.error:
        return Colors.redAccent;
    }
  }

  IconData _statusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.idle:
        return Icons.cloud_upload_outlined;
      case UploadStatus.uploading:
        return Icons.cloud_sync_outlined;
      case UploadStatus.done:
        return Icons.cloud_done_outlined;
      case UploadStatus.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildFirestoreStructureCard()),
            SliverToBoxAdapter(child: _buildLanguageCards()),
            SliverToBoxAdapter(child: _buildProgressSection()),
            SliverToBoxAdapter(child: _buildUploadButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFFB347)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.temple_hindu_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shiv Amrut Darshan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Firebase Firestore Data Uploader',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  const Color(0xFFFF6B00).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF6B00),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This app uploads 3 JSON files (English, Gujarati, Hindi) into Firebase Firestore under the ShivAmrutDarshan collection.',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreStructureCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  color: Color(0xFF4FC3F7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Firestore Structure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStructureRow('📁', 'ShivAmrutDarshan', 0, isCollection: true),
            _buildStructureRow('📄', 'en / gu / hi', 1, isDoc: true),
            _buildStructureRow('🔤', 'm_id1..m_id7 (menu labels)', 2),
            _buildStructureRow('📂', 'id1, id2, id3, id4, id5, id7', 2,
                isCollection: true),
            _buildStructureRow('📄', 'titles → {id1_1, id1_2, ...}', 3,
                isDoc: true),
            _buildStructureRow('📄', 'stories → {id1_1, id1_2, ...}', 3,
                isDoc: true),
            const SizedBox(height: 12),
            _buildStructureRow('📁', 'shivQuotes', 0, isCollection: true),
            _buildStructureRow('📄', 'en / gu / hi (200 quotes directly)', 1, isDoc: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureRow(
    String emoji,
    String label,
    int indent, {
    bool isCollection = false,
    bool isDoc = false,
  }) {
    Color color = Colors.grey.shade400;
    if (isCollection) color = const Color(0xFF4FC3F7);
    if (isDoc) color = const Color(0xFFA5D6A7);

    return Padding(
      padding: EdgeInsets.only(left: indent * 16.0, top: 6),
      child: Row(
        children: [
          if (indent > 0) ...[
            Text(
              '└─ ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          Text('$emoji ', style: const TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: isCollection || isDoc
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATA FILES',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...['en', 'gu', 'hi'].map((code) => _buildLanguageCard(code)),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(String code) {
    final status = _languageStatus[code]!;
    final isUploading = status == UploadStatus.uploading;

    final Map<String, String> fileInfo = {
      'en': 'data_english.json • 470 KB • 18 sections',
      'gu': 'data_gujrati.json • 975 KB • 18 sections',
      'hi': 'data_hindi.json • 937 KB • 18 sections',
    };

    final Map<String, String> flagEmoji = {
      'en': '🇬🇧',
      'gu': '🇮🇳',
      'hi': '🇮🇳',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploading
              ? const Color(0xFFFF6B00).withValues(alpha: 0.6)
              : status == UploadStatus.done
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
          width: isUploading ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(flagEmoji[code]!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _languageLabels[code]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileInfo[code]!,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isUploading ? _pulseAnimation.value : 1.0,
                child: Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 26,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (!_isUploading && _progress == 0.0 && _statusMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Progress',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF6B00),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _progress == 1.0
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _isUploading ? null : _startUpload,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 60,
          decoration: BoxDecoration(
            gradient: _isUploading
                ? LinearGradient(
                    colors: [
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8C42)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isUploading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Uploading to Firestore...',
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _progress == 1.0
                            ? 'Re-Upload All Data'
                            : 'Upload All Data to Firebase',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum UploadStatus { idle, uploading, done, error }

class _SectionConfig {
  final String titlesKey;
  final String? storiesKey;
  const _SectionConfig(this.titlesKey, this.storiesKey);
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}
