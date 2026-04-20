import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../models/comic_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;

class BookDetailScreen extends StatelessWidget {
  final ComicModel comic;
  const BookDetailScreen({super.key, required this.comic});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha:0.6))),
                  ],
                  if (comic.description != null) ...[
                    const SizedBox(height: 12),
                    Text(comic.description!,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha:0.6),
                            height: 1.5)),
                  ],
                  const SizedBox(height: 24),
                  if (comic.pdfUrl == null)
                    Center(
                      child: Text('No PDF available yet.',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha:0.6))),
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
  bool _disposed = false; // ← key flag
  String? _localPath;
  String _error = '';
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfViewController;

  spdf.PdfDocument? _pdfDoc;
  final Map<int, String> _pageTexts = {};
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
      final file =
      File('${dir.path}/book_${widget.comic.id}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      _pdfDoc =
          spdf.PdfDocument(inputBytes: response.bodyBytes);
      if (!_disposed && mounted) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
        _extractPageText(0);
      }
    } catch (e) {
      if (!_disposed && mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _extractPageText(int pageIndex) async {
    if (_disposed) return;
    if (_pdfDoc == null) return;
    if (_pageTexts.containsKey(pageIndex)) return;
    try {
      final extractor = spdf.PdfTextExtractor(_pdfDoc!);
      final text = extractor.extractText(
        startPageIndex: pageIndex,
        endPageIndex: pageIndex,
      );
      if (!_disposed && mounted) {
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

    _tts.setCompletionHandler(() async {
      // _disposed check is the critical guard here
      if (_disposed || !_isSpeaking) return;
      if (_currentPage < _totalPages - 1) {
        await _pdfViewController?.setPage(_currentPage + 1);
        await Future.delayed(const Duration(milliseconds: 500));
        if (_disposed || !_isSpeaking) return; // check again after delay
        await _speakCurrentPage();
      } else {
        _isSpeaking = false;
        if (!_disposed && mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                Text('You reached the end of the book! 🎉')),
          );
        }
      }
    });
  }

  Future<void> _speakCurrentPage() async {
    if (_disposed || !mounted) return;
    if (!_pageTexts.containsKey(_currentPage)) {
      if (mounted) setState(() => _isExtracting = true);
      await _extractPageText(_currentPage);
      if (_disposed) return;
      if (mounted) setState(() => _isExtracting = false);
    }
    if (_disposed || !_isSpeaking) return;
    final text = _pageTexts[_currentPage] ?? '';
    await _tts.speak(text.isEmpty ? 'No text on this page.' : text);
  }

  Future<void> _toggleTts() async {
    if (_disposed) return;
    if (_isSpeaking) {
      _isSpeaking = false; // set flag BEFORE stop
      _tts.setCompletionHandler(() {});
      await _tts.stop();
      if (!_disposed && mounted) setState(() {});
    } else {
      if (mounted) setState(() => _isSpeaking = true);
      await _speakCurrentPage();
    }
  }

  Future<void> _goToPage(int page) async {
    if (_disposed) return;
    if (page < 0 || page >= _totalPages) return;
    final wasPlaying = _isSpeaking;
    _isSpeaking = false; // flag off before stop
    _tts.setCompletionHandler(() {});
    await _tts.stop();
    if (_disposed) return;
    await _pdfViewController?.setPage(page);
    _extractPageText(page);
    if (wasPlaying && !_disposed) {
      _isSpeaking = true;
      await Future.delayed(const Duration(milliseconds: 400));
      if (_disposed || !_isSpeaking) return;
      await _speakCurrentPage();
    }
  }

  @override
  void dispose() {
    _disposed = true;  // set FIRST — blocks all async callbacks
    _isSpeaking = false;
    _tts.setCompletionHandler(() {});
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.comic.title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(
                    fontSize: 12, color: Colors.white60),
              ),
          ],
        ),
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
              style:
              const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: _localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              onRender: (pages) {
                if (!_disposed && mounted) {
                  setState(
                          () => _totalPages = pages ?? 0);
                }
              },
              onViewCreated: (controller) {
                _pdfViewController = controller;
              },
              onPageChanged: (page, total) {
                if (_disposed) return;
                final newPage = page ?? 0;
                if (mounted) {
                  setState(() {
                    _currentPage = newPage;
                    _totalPages = total ?? 0;
                  });
                }
                _extractPageText(newPage);
                if (newPage + 1 < (total ?? 0)) {
                  _extractPageText(newPage + 1);
                }
              },
              onError: (error) {
                if (!_disposed && mounted) {
                  setState(
                          () => _error = error.toString());
                }
              },
            ),
          ),

          // Bottom control bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () =>
                      _goToPage(_currentPage - 1)
                      : null,
                  icon: const Icon(
                      Icons.arrow_back_ios_rounded),
                  color: _currentPage > 0
                      ? Colors.white
                      : Colors.white24,
                  tooltip: 'Previous page',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _totalPages > 0
                          ? '${_currentPage + 1} / $_totalPages'
                          : '-',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                  _currentPage < _totalPages - 1
                      ? () => _goToPage(
                      _currentPage + 1)
                      : null,
                  icon: const Icon(
                      Icons.arrow_forward_ios_rounded),
                  color:
                  _currentPage < _totalPages - 1
                      ? Colors.white
                      : Colors.white24,
                  tooltip: 'Next page',
                ),
                const SizedBox(width: 8),
                Container(
                    width: 1,
                    height: 28,
                    color: Colors.white24),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isExtracting
                      ? null
                      : _toggleTts,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSpeaking
                          ? AppTheme.accent
                          .withValues(alpha:0.2)
                          : Colors.white
                          .withValues(alpha:0.08),
                      borderRadius:
                      BorderRadius.circular(20),
                      border: Border.all(
                        color: _isSpeaking
                            ? AppTheme.accent
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isExtracting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          _isSpeaking
                              ? Icons.volume_up
                              : Icons.volume_off,
                          color: _isSpeaking
                              ? AppTheme.accent
                              : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isSpeaking ? 'Stop' : 'Read',
                          style: TextStyle(
                            color: _isSpeaking
                                ? AppTheme.accent
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
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
}