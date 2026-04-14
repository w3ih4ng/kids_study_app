import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/lesson_model.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  List<LessonModel> _lessons = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedSubject = 'Math';
  String _selectedDifficulty = 'Easy';
  String _selectedType = 'youtube';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final lessons = await LessonService.getLessons();
    if (mounted) setState(() { _lessons = lessons; _isLoading = false; });
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _urlController.clear();
    _selectedSubject = 'Math';
    _selectedDifficulty = 'Easy';
    _selectedType = 'youtube';
  }

  Future<void> _showForm({LessonModel? lesson}) async {
    if (lesson != null) {
      _titleController.text = lesson.title;
      _descController.text = lesson.description ?? '';
      _urlController.text = lesson.contentUrl ?? '';
      _selectedSubject = lesson.subject;
      _selectedDifficulty = lesson.difficulty;
      _selectedType = lesson.type;
    } else {
      _resetForm();
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
                Text(lesson == null ? 'Add New Lesson' : 'Edit Lesson',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Lesson Title',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                // Subject dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder()),
                  items: ['Math', 'English']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => _selectedSubject = v!),
                ),
                const SizedBox(height: 12),
                // Difficulty dropdown
                DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder()),
                  items: ['Easy', 'Medium', 'Hard']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => _selectedDifficulty = v!),
                ),
                const SizedBox(height: 12),
                // Type toggle
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                      labelText: 'Content Type',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: 'youtube', child: Text('YouTube Video')),
                    const DropdownMenuItem(
                        value: 'image', child: Text('Image')),
                  ],
                  onChanged: (v) =>
                      setModalState(() => _selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'youtube'
                        ? 'YouTube URL'
                        : 'Image URL',
                    hintText: _selectedType == 'youtube'
                        ? 'https://youtube.com/watch?v=...'
                        : 'https://...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) return;
                    if (lesson == null) {
                      await LessonService.createLesson(
                        title: _titleController.text.trim(),
                        subject: _selectedSubject,
                        difficulty: _selectedDifficulty,
                        type: _selectedType,
                        contentUrl: _urlController.text.trim(),
                        description: _descController.text.trim(),
                      );
                    } else {
                      await LessonService.updateLesson(lesson.id, {
                        'title': _titleController.text.trim(),
                        'subject': _selectedSubject,
                        'difficulty': _selectedDifficulty,
                        'type': _selectedType,
                        'content_url': _urlController.text.trim(),
                        'description': _descController.text.trim(),
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
        content: Text('Delete "${lesson.title}"?'),
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
      await LessonService.deleteLesson(lesson.id);
      _load();
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
                backgroundColor:
                lesson.subject == 'Math'
                    ? AppTheme.lessonsColor.withOpacity(0.2)
                    : AppTheme.quizzesColor.withOpacity(0.2),
                child: Icon(
                  lesson.type == 'youtube'
                      ? Icons.play_circle
                      : Icons.image,
                  color: lesson.subject == 'Math'
                      ? AppTheme.lessonsColor
                      : AppTheme.quizzesColor,
                ),
              ),
              title: Text(lesson.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${lesson.subject} · ${lesson.difficulty}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppTheme.textSecondary),
                    onPressed: () => _showForm(lesson: lesson),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppTheme.danger),
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