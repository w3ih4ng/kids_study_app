import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/comic_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/comic_model.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  List<ComicModel> _comics = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  String? _coverUrl;
  bool _isUploading = false;

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

  Future<String?> _uploadImage(
      StateSetter setModalState, String prefix) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Image',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child:
                  Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: Icon(Icons.photo_library, color: Colors.white)),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picked = await picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 80);
    if (picked == null) return null;

    setModalState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('comics')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('comics')
          .getPublicUrl(fileName);

      setModalState(() => _isUploading = false);
      return url;
    } catch (e) {
      setModalState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  Future<void> _showForm({ComicModel? comic}) async {
    if (comic != null) {
      _titleController.text = comic.title;
      _authorController.text = comic.author ?? '';
      _descController.text = comic.description ?? '';
      _coverUrl = comic.coverUrl;
    } else {
      _titleController.clear();
      _authorController.clear();
      _descController.clear();
      _coverUrl = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(comic == null ? 'Add New Book' : 'Edit Book',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Cover image
                GestureDetector(
                  onTap: () async {
                    final url =
                    await _uploadImage(setModalState, 'cover');
                    if (url != null) {
                      setModalState(() => _coverUrl = url);
                    }
                  },
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.booksColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.booksColor.withOpacity(0.3)),
                    ),
                    child: _isUploading
                        ? const Center(
                        child: CircularProgressIndicator())
                        : _coverUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity),
                    )
                        : const Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 40,
                            color: AppTheme.booksColor),
                        SizedBox(height: 8),
                        Text('Tap to add cover image',
                            style: TextStyle(
                                color: AppTheme.booksColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Book Title',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                      labelText: 'Author (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) return;
                    if (comic == null) {
                      await ComicService.createComic(
                        title: _titleController.text.trim(),
                        author: _authorController.text.trim().isEmpty
                            ? null
                            : _authorController.text.trim(),
                        description:
                        _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        coverUrl: _coverUrl,
                      );
                    } else {
                      await ComicService.updateComic(comic.id, {
                        'title': _titleController.text.trim(),
                        'author':
                        _authorController.text.trim().isEmpty
                            ? null
                            : _authorController.text.trim(),
                        'description':
                        _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        'cover_url': _coverUrl,
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                      comic == null ? 'Add Book' : 'Update Book'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _managePages(ComicModel comic) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AdminBookPagesScreen(comic: comic)),
    );
    _load();
  }

  Future<void> _delete(ComicModel comic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Delete "${comic.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      await ComicService.deleteComic(comic.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Books')),
      body: _isLoading
          ? const LoadingWidget()
          : _comics.isEmpty
          ? EmptyStateWidget(
        message: 'No books yet.\nTap + to add one.',
        icon: Icons.menu_book_outlined,
        actionLabel: 'Add Book',
        onAction: () => _showForm(),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _comics.length,
        itemBuilder: (_, i) {
          final comic = _comics[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: comic.coverUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  comic.coverUrl!,
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
                  : const Icon(Icons.menu_book,
                  color: AppTheme.booksColor, size: 40),
              title: Text(comic.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${comic.pages.length} pages · ${comic.author ?? 'Unknown author'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manage pages
                  IconButton(
                    icon: const Icon(Icons.auto_stories,
                        color: AppTheme.booksColor),
                    tooltip: 'Manage Pages',
                    onPressed: () => _managePages(comic),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppTheme.textSecondary),
                    onPressed: () => _showForm(comic: comic),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppTheme.danger),
                    onPressed: () => _delete(comic),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Admin Book Pages Screen ───────────────────────────────────────

class AdminBookPagesScreen extends StatefulWidget {
  final ComicModel comic;
  const AdminBookPagesScreen({super.key, required this.comic});

  @override
  State<AdminBookPagesScreen> createState() => _AdminBookPagesScreenState();
}

class _AdminBookPagesScreenState extends State<AdminBookPagesScreen> {
  late ComicModel _comic;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _comic = widget.comic;
  }

  Future<void> _reload() async {
    final comics = await ComicService.getComics();
    final updated = comics.firstWhere((c) => c.id == _comic.id);
    if (mounted) setState(() => _comic = updated);
  }

  Future<void> _addPage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Add Page',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child:
                  Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: Icon(Icons.photo_library, color: Colors.white)),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName =
          'page_${_comic.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('comics')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('comics')
          .getPublicUrl(fileName);

      await ComicService.addPage(
        comicId: _comic.id,
        pageUrl: url,
        currentPages: _comic.pages,
      );

      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_comic.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_comic.pages.length} pages',
              style:
              const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isUploading
          ? const LoadingWidget(message: 'Uploading page...')
          : _comic.pages.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories,
                size: 72, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('No pages yet',
                style: TextStyle(
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addPage,
              icon: const Icon(Icons.add),
              label: const Text('Add First Page'),
            ),
          ],
        ),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _comic.pages.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          final pages = List<String>.from(_comic.pages);
          final page = pages.removeAt(oldIndex);
          pages.insert(newIndex, page);
          await ComicService.updateComic(
              _comic.id, {'pages': pages});
          _reload();
        },
        itemBuilder: (_, i) {
          return Card(
            key: ValueKey(_comic.pages[i]),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  _comic.pages[i],
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text('Page ${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: const Text('Drag to reorder'),
              trailing: IconButton(
                icon: const Icon(Icons.delete,
                    color: AppTheme.danger),
                onPressed: () async {
                  await ComicService.removePage(
                    comicId: _comic.id,
                    pageIndex: i,
                    currentPages: _comic.pages,
                  );
                  _reload();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPage,
        backgroundColor: AppTheme.booksColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}