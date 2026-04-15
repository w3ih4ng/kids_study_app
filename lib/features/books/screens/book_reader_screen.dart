import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/comic_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;

class BookDetailScreen extends StatelessWidget {
  final ComicModel comic;
  const BookDetailScreen({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(comic.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comic.coverUrl != null)
              Image.network(
                comic.coverUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comic.title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  if (comic.author != null) ...[
                    const SizedBox(height: 4),
                    Text('by ${comic.author}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary)),
                  ],
                  if (comic.description != null) ...[
                    const SizedBox(height: 12),
                    Text(comic.description!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                  if (comic.pdfUrl == null)
                    const Center(
                      child: Text('No PDF available yet.',
                          style: TextStyle(
                              color: AppTheme.textSecondary)),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookReaderScreen(comic: comic),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Start Reading'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.booksColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookReaderScreen extends StatefulWidget {
  final ComicModel comic;
  const BookReaderScreen({super.key, required this.comic});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isLoading = true;
  String? _localPath;
  String _error = '';
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfViewController;

  // Text extraction
  spdf.PdfDocument? _pdfDoc;
  Map<int, String> _pageTexts = {};
  bool _isExtracting = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
    _setupTts();
  }

  Future<void> _loadPdf() async {
    try {
      final response =
      await http.get(Uri.parse(widget.comic.pdfUrl!));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/book_${widget.comic.id}.pdf');
      await file.writeAsBytes(response.bodyBytes);

      // Load PDF for text extraction
      _pdfDoc = spdf.PdfDocument(inputBytes: response.bodyBytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
        _extractPageText(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _extractPageText(int pageIndex) async {
    if (_pdfDoc == null) return;
    if (_pageTexts.containsKey(pageIndex)) return;

    try {
      final extractor = spdf.PdfTextExtractor(_pdfDoc!);
      final text = extractor.extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
      if (mounted) {
        setState(() => _pageTexts[pageIndex] = text.trim());
      }
    } catch (e) {
      _pageTexts[pageIndex] = '';
    }
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Auto continue to next page when done reading
    _tts.setCompletionHandler(() async {
      if (!mounted || !_isSpeaking) return;
      // Move to next page automatically
      if (_currentPage < _totalPages - 1) {
        await _pdfViewController?.setPage(_currentPage + 1);
        await Future.delayed(const Duration(milliseconds: 500));
        await _speakCurrentPage();
      } else {
        // End of book
        if (mounted) setState(() => _isSpeaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You reached the end of the book! 🎉')),
        );
      }
    });
  }

  Future<void> _speakCurrentPage() async {
    if (!mounted) return;

    // Extract text if not yet done
    if (!_pageTexts.containsKey(_currentPage)) {
      setState(() => _isExtracting = true);
      await _extractPageText(_currentPage);
      if (mounted) setState(() => _isExtracting = false);
    }

    final text = _pageTexts[_currentPage] ?? '';

    if (text.isEmpty) {
      // No text on this page — skip to next
      await _tts.speak('No text on this page.');
    } else {
      await _tts.speak(text);
    }
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      if (mounted) setState(() => _isSpeaking = true);
      await _speakCurrentPage();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _pdfDoc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _totalPages > 0
              ? 'Page ${_currentPage + 1} / $_totalPages'
              : widget.comic.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // TTS status indicator
          if (_isExtracting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: _isSpeaking ? AppTheme.accent : Colors.white,
            ),
            tooltip: _isSpeaking ? 'Stop reading' : 'Read aloud',
            onPressed: _isExtracting ? null : _toggleTts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading book...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      )
          : _error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_error,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      )
          : Stack(
        children: [
          PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) {
              setState(() => _totalPages = pages ?? 0);
            },
            onViewCreated: (controller) {
              _pdfViewController = controller;
            },
            onPageChanged: (page, total) {
              final newPage = page ?? 0;
              setState(() {
                _currentPage = newPage;
                _totalPages = total ?? 0;
              });
              // Pre-extract next page text
              _extractPageText(newPage);
              if (newPage + 1 < (total ?? 0)) {
                _extractPageText(newPage + 1);
              }
              // If TTS is on, reading continues
              // via completion handler automatically
            },
            onError: (error) {
              setState(() => _error = error.toString());
            },
          ),
          // TTS active banner
          if (_isSpeaking)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up,
                        color: AppTheme.accent, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Reading aloud... tap 🔊 to stop',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                    // Manual next page button
                    if (!_isExtracting)
                      TextButton(
                        onPressed: () async {
                          await _tts.stop();
                          if (_currentPage < _totalPages - 1) {
                            await _pdfViewController
                                ?.setPage(_currentPage + 1);
                          }
                        },
                        child: const Text('Skip →',
                            style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}