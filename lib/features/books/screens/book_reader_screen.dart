import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/comic_model.dart';

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
            // Cover
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.auto_stories,
                          color: AppTheme.booksColor),
                      const SizedBox(width: 8),
                      Text('${comic.pages.length} pages',
                          style: const TextStyle(
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (comic.pages.isEmpty)
                    const Center(
                      child: Text('No pages available yet.',
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
                        icon: const Icon(Icons.play_arrow),
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
  final PageController _pageController = PageController();
  final FlutterTts _tts = FlutterTts();
  int _currentPage = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      // Read page number as TTS (since pages are images)
      await _tts.speak(
          'Page ${_currentPage + 1} of ${widget.comic.pages.length}. ${widget.comic.title}.');
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
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
          'Page ${_currentPage + 1} / ${widget.comic.pages.length}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          // TTS button
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: _isSpeaking ? AppTheme.accent : Colors.white,
            ),
            tooltip: 'Read aloud',
            onPressed: _toggleTts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Page viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.comic.pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                if (_isSpeaking) {
                  _tts.speak(
                      'Page ${index + 1} of ${widget.comic.pages.length}.');
                }
              },
              itemBuilder: (_, i) => InteractiveViewer(
                child: Image.network(
                  widget.comic.pages[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) =>
                  progress == null
                      ? child
                      : const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white)),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
          // Navigation bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                    duration:
                    const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                      : null,
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white),
                ),
                // Page dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.comic.pages.length > 10
                        ? 10
                        : widget.comic.pages.length,
                        (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentPage ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? AppTheme.booksColor
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                  _currentPage < widget.comic.pages.length - 1
                      ? () => _pageController.nextPage(
                    duration:
                    const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}