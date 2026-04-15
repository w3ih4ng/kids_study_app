import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  String? _pdfUrl;
  bool _isUploading = false;
  String _uploadStatus = '';

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

  Future<String?> _uploadCoverImage(StateSetter setModalState) async {
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
            const Text('Select Cover Image',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.camera_alt, color: Colors.white)),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child:
                  Icon(Icons.photo_library, color: Colors.white)),
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
        source: source, maxWidth: 512, imageQuality: 80);
    if (picked == null) return null;

    setModalState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading cover...';
    });

    try {
      final bytes = await picked.readAsBytes();
      final fileName =
          'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('comics')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));

      final url = Supabase.instance.client.storage
          .from('comics')
          .getPublicUrl(fileName);

      setModalState(() {
        _coverUrl = url;
        _isUploading = false;
        _uploadStatus = '';
      });
      return url;
    } catch (e) {
      setModalState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  Future<String?> _uploadPdf(StateSetter setModalState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    setModalState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading PDF...';
    });

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final fileName =
          'book_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await Supabase.instance.client.storage
          .from('pdfs')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/pdf',
          ));

      final url = Supabase.instance.client.storage
          .from('pdfs')
          .getPublicUrl(fileName);

      setModalState(() {
        _pdfUrl = url;
        _isUploading = false;
        _uploadStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF uploaded successfully!')));
      }
      return url;
    } catch (e) {
      setModalState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF upload failed: $e')));
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
      _pdfUrl = comic.pdfUrl;
    } else {
      _titleController.clear();
      _authorController.clear();
      _descController.clear();
      _coverUrl = null;
      _pdfUrl = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
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
                const Text('Cover Image',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading
                      ? null
                      : () => _uploadCoverImage(setModalState),
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.booksColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.booksColor.withOpacity(0.3)),
                    ),
                    child: _coverUrl != null
                        ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _coverUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius:
                              BorderRadius.circular(8),
                            ),
                            child: const Text('Tap to change',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11)),
                          ),
                        ),
                      ],
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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

                // PDF Upload
                const Text('Book PDF',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading
                      ? null
                      : () => _uploadPdf(setModalState),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _pdfUrl != null
                          ? AppTheme.success.withOpacity(0.1)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pdfUrl != null
                            ? AppTheme.success
                            : AppTheme.border,
                      ),
                    ),
                    child: _isUploading &&
                        _uploadStatus.contains('PDF')
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 12),
                        Text('Uploading PDF...'),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                          _pdfUrl != null
                              ? Icons.picture_as_pdf
                              : Icons.upload_file,
                          color: _pdfUrl != null
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pdfUrl != null
                                    ? 'PDF uploaded ✓'
                                    : 'Upload PDF file',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _pdfUrl != null
                                      ? AppTheme.success
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _pdfUrl != null
                                    ? 'Tap to replace'
                                    : 'Tap to select a PDF file',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
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
                  onPressed: _isUploading
                      ? null
                      : () async {
                    if (_titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text('Please enter a title')));
                      return;
                    }
                    if (comic == null) {
                      await ComicService.createComic(
                        title: _titleController.text.trim(),
                        author:
                        _authorController.text.trim().isEmpty
                            ? null
                            : _authorController.text.trim(),
                        description:
                        _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        coverUrl: _coverUrl,
                        pdfUrl: _pdfUrl,
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
                        'pdf_url': _pdfUrl,
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
                '${comic.author ?? 'Unknown author'} · ${comic.pdfUrl != null ? '📄 PDF ready' : '⚠️ No PDF'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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