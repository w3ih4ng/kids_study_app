import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/comic_service.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/comic_model.dart';
import 'book_reader_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<ComicModel> _comics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final comics = await ComicService.getComics();
    if (mounted) {
      setState(() {
        _comics = comics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const LoadingWidget()
        : _comics.isEmpty
        ? const EmptyStateWidget(
            message: 'No books available yet.',
            icon: Icons.menu_book_outlined,
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _comics.length,
            itemBuilder: (_, i) => _comicCard(_comics[i]),
          );
  }

  Widget _comicCard(ComicModel comic) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(comic: comic)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: comic.coverUrl != null
                    ? Image.network(
                        comic.coverUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.booksColor.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.menu_book,
                            size: 48,
                            color: AppTheme.booksColor,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.booksColor.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.menu_book,
                          size: 48,
                          color: AppTheme.booksColor,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (comic.author != null)
                    Text(
                      comic.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        comic.pdfUrl != null
                            ? Icons.picture_as_pdf
                            : Icons.hourglass_empty,
                        size: 12,
                        color: comic.pdfUrl != null
                            ? AppTheme.success
                            : cs.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comic.pdfUrl != null ? 'PDF Ready' : 'Coming soon',
                        style: TextStyle(
                          fontSize: 11,
                          color: comic.pdfUrl != null
                              ? AppTheme.success
                              : cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
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
