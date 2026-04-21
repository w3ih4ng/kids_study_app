import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/lesson_service.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/lesson_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_snackbar.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  List<LessonModel> _lessons = [];
  bool _isLoading = true;

  bool _isUploading = false;
  String? _uploadedImageUrl;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedSubject = 'Math';
  String _selectedDifficulty = 'Easy';
  String _selectedType = 'youtube';
  String _selectedAgeLevel = '6+';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final lessons = await LessonService.getLessons();
    if (mounted)
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _urlController.clear();
    _selectedSubject = 'Math';
    _selectedDifficulty = 'Easy';
    _selectedType = 'youtube';
    _uploadedImageUrl = null;
    _selectedAgeLevel = '6+';
  }

  Future<void> _showForm({LessonModel? lesson}) async {
    if (lesson != null) {
      _titleController.text = lesson.title;
      _descController.text = lesson.description ?? '';
      _urlController.text = lesson.contentUrl ?? '';
      _selectedSubject = lesson.subject;
      _selectedDifficulty = lesson.difficulty;
      _selectedType = lesson.type;
      _selectedAgeLevel = lesson.ageLevel;
    } else {
      _resetForm();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                Text(
                  lesson == null ? 'Add New Lesson' : 'Edit Lesson',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Lesson Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Subject dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Math', 'English']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => _selectedSubject = v!),
                ),
                const SizedBox(height: 12),
                // Difficulty dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Easy', 'Medium', 'Hard']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => _selectedDifficulty = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAgeLevel,
                  decoration: const InputDecoration(
                    labelText: 'Age Level',
                    border: OutlineInputBorder(),
                  ),
                  items: ['4+', '5+', '6+', '7+', '8+']
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text('$a years old'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => _selectedAgeLevel = v!),
                ),
                const SizedBox(height: 12),
                // Type toggle
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Content Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'youtube',
                      child: Text('YouTube Video'),
                    ),
                    const DropdownMenuItem(
                      value: 'image',
                      child: Text('Image'),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => _selectedType = v!),
                ),
                const SizedBox(height: 12),
                if (_selectedType == 'youtube')
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube URL',
                      hintText: 'https://youtube.com/watch?v=...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.play_circle, color: Colors.red),
                    ),
                  )
                else ...[
                  if (_uploadedImageUrl != null ||
                      _urlController.text.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        // Full screen preview
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.network(
                                    _uploadedImageUrl ?? _urlController.text,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                // Close button
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _uploadedImageUrl ?? _urlController.text,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 160,
                                color: AppTheme.background,
                                child: const Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          ),
                          // Tap to preview hint
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () => _pickAndUploadImage(setModalState),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isUploading
                          ? 'Uploading...'
                          : _uploadedImageUrl != null ||
                                _urlController.text.isNotEmpty
                          ? 'Change Image'
                          : 'Upload Image',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) {
                      AppSnackbar.warning(
                        context,
                        'Please enter a lesson title.',
                      );
                      return;
                    }
                    try {
                      if (lesson == null) {
                        await LessonService.createLesson(
                          title: _titleController.text.trim(),
                          subject: _selectedSubject,
                          difficulty: _selectedDifficulty,
                          type: _selectedType,
                          contentUrl: _urlController.text.trim(),
                          description: _descController.text.trim(),
                          ageLevel: _selectedAgeLevel,
                        );
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        await NotificationService.notifyAll(
                          title: '📚 New Lesson Available!',
                          body:
                              '${_titleController.text.trim()} has been added!',
                        );
                        if (context.mounted) {
                          AppSnackbar.success(
                            context,
                            'Lesson created successfully!',
                          );
                        }
                      } else {
                        await LessonService.updateLesson(lesson.id, {
                          'title': _titleController.text.trim(),
                          'subject': _selectedSubject,
                          'difficulty': _selectedDifficulty,
                          'type': _selectedType,
                          'content_url': _urlController.text.trim(),
                          'description': _descController.text.trim(),
                          'age_level': _selectedAgeLevel,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        if (context.mounted) {
                          AppSnackbar.success(
                            context,
                            'Lesson updated successfully!',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.error(context, 'Failed: ${e.toString()}');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(lesson == null ? 'Add Lesson' : 'Update Lesson'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(LessonModel lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Delete "${lesson.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await LessonService.deleteLesson(lesson.id);
        _load();
        if (mounted) {
          AppSnackbar.success(context, '"${lesson.title}" deleted.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }

  Future<String?> _pickAndUploadImage(StateSetter setModalState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Select Image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.secondary,
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (picked == null) return null;

    setModalState(() => _isUploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName = 'lesson_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('lessons')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = Supabase.instance.client.storage
          .from('lessons')
          .getPublicUrl(fileName);

      setModalState(() {
        _uploadedImageUrl = url;
        _urlController.text = url;
        _isUploading = false;
      });

      return url;
    } catch (e) {
      setModalState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Lessons')),
      body: _isLoading
          ? const LoadingWidget()
          : _lessons.isEmpty
          ? EmptyStateWidget(
              message: 'No lessons yet.\nTap + to add one.',
              icon: Icons.play_lesson_outlined,
              actionLabel: 'Add Lesson',
              onAction: () => _showForm(),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lessons.length,
              itemBuilder: (_, i) {
                final lesson = _lessons[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: lesson.subject == 'Math'
                          ? AppTheme.lessonsColor.withValues(alpha: 0.2)
                          : AppTheme.quizzesColor.withValues(alpha: 0.2),
                      child: Icon(
                        lesson.type == 'youtube'
                            ? Icons.play_circle
                            : Icons.image,
                        color: lesson.subject == 'Math'
                            ? AppTheme.lessonsColor
                            : AppTheme.quizzesColor,
                      ),
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${lesson.subject} · ${lesson.difficulty}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => _showForm(lesson: lesson),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.danger,
                          ),
                          onPressed: () => _delete(lesson),
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
