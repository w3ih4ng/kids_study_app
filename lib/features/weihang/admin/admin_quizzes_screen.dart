import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/lesson_model.dart';
import '../../../models/quiz_model.dart';
import 'admin_quiz_questions_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/app_snackbar.dart';

class AdminQuizzesScreen extends StatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  State<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends State<AdminQuizzesScreen> {
  List<QuizModel> _quizzes = [];
  List<LessonModel> _lessons = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _coinController = TextEditingController(text: '100');
  String _selectedSubject = 'Math';
  String? _selectedLessonId;

  String _selectedAgeLevel = '6+';
  String? _thumbnailUrl;
  bool _isUploadingThumb = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final quizzes = await QuizService.getQuizzes();
    final lessons = await LessonService.getLessons();
    if (mounted) {
      setState(() {
        _quizzes = quizzes;
        _lessons = lessons;
        _isLoading = false;
      });
    }
  }

  Future<void> _showForm({QuizModel? quiz}) async {
    if (quiz != null) {
      _titleController.text = quiz.title;
      _coinController.text = quiz.coinValue.toString();
      _selectedSubject = quiz.subject;
      _selectedLessonId = quiz.lessonId;
      _selectedAgeLevel = quiz.ageLevel;
      _thumbnailUrl = quiz.thumbnailUrl;
    } else {
      _titleController.clear();
      _coinController.text = '100';
      _selectedSubject = 'Math';
      _selectedLessonId = null;
      _selectedAgeLevel = '6+';
      _thumbnailUrl = null;
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
                Text(quiz == null ? 'Add New Quiz' : 'Edit Quiz',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
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
                // Optional lesson link
                DropdownButtonFormField<String?>(
                  initialValue: _selectedLessonId,
                  decoration: const InputDecoration(
                      labelText: 'Linked Lesson (optional)',
                      border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Standalone quiz')),
                    ..._lessons.map((l) =>
                        DropdownMenuItem(value: l.id, child: Text(l.title))),
                  ],
                  onChanged: (v) =>
                      setModalState(() => _selectedLessonId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAgeLevel,
                  decoration: const InputDecoration(
                      labelText: 'Age Level',
                      border: OutlineInputBorder()),
                  items: ['4+', '5+', '6+', '7+', '8+']
                      .map((a) => DropdownMenuItem(value: a, child: Text('$a years old')))
                      .toList(),
                  onChanged: (v) => setModalState(() => _selectedAgeLevel = v!),
                ),
                const SizedBox(height: 12),
                // Thumbnail upload
                const Text('Thumbnail (optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _isUploadingThumb
                      ? null
                      : () => _pickThumbnail(setModalState),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: _thumbnailUrl != null
                          ? Colors.transparent
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: _isUploadingThumb
                        ? const Center(child: CircularProgressIndicator())
                        : _thumbnailUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_thumbnailUrl!,
                          fit: BoxFit.cover, width: double.infinity),
                    )
                        : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            color: AppTheme.textSecondary, size: 32),
                        SizedBox(height: 4),
                        Text('Tap to add thumbnail',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _coinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Total Coin Value',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) {
                      AppSnackbar.warning(context, 'Please enter a quiz title.');
                      return;
                    }
                    try {
                      if (quiz == null) {
                        await QuizService.createQuiz(
                          title: _titleController.text.trim(),
                          subject: _selectedSubject,
                          lessonId: _selectedLessonId,
                          coinValue: int.tryParse(_coinController.text) ?? 100,
                          ageLevel: _selectedAgeLevel,
                          thumbnailUrl: _thumbnailUrl,
                        );
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        await NotificationService.notifyAll(
                          title: '🎯 New Quiz Available!',
                          body: '${_titleController.text.trim()} is ready!',
                        );
                        if (context.mounted) {
                          AppSnackbar.success(context, 'Quiz created successfully!');
                        }
                      } else {
                        await QuizService.updateQuiz(quiz.id, {
                          'title': _titleController.text.trim(),
                          'subject': _selectedSubject,
                          'lesson_id': _selectedLessonId,
                          'coin_value': int.tryParse(_coinController.text) ?? 100,
                          'age_level': _selectedAgeLevel,
                          'thumbnail_url': _thumbnailUrl,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        if (context.mounted) {
                          AppSnackbar.success(context, 'Quiz updated successfully!');
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
                  child: Text(quiz == null ? 'Add Quiz' : 'Update Quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(QuizModel quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Delete "${quiz.title}"? All questions will also be deleted.'),
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
      try {
        await QuizService.deleteQuiz(quiz.id);
        _load();
        if (mounted) {
          AppSnackbar.success(context, '"${quiz.title}" deleted.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _pickThumbnail(StateSetter setModalState) async {
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
            const Text('Quiz Thumbnail',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        source: source, maxWidth: 512, imageQuality: 80);
    if (picked == null) return;

    setModalState(() => _isUploadingThumb = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName = 'quiz_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('quizzes')
          .uploadBinary(fileName, bytes,
          fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage
          .from('quizzes')
          .getPublicUrl(fileName);
      setModalState(() {
        _thumbnailUrl = url;
        _isUploadingThumb = false;
      });
    } catch (e) {
      setModalState(() => _isUploadingThumb = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Quizzes')),
      body: _isLoading
          ? const LoadingWidget()
          : _quizzes.isEmpty
          ? EmptyStateWidget(
        message: 'No quizzes yet.\nTap + to add one.',
        icon: Icons.quiz_outlined,
        actionLabel: 'Add Quiz',
        onAction: () => _showForm(),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quizzes.length,
        itemBuilder: (_, i) {
          final quiz = _quizzes[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                AppTheme.quizzesColor.withValues(alpha:0.2),
                child: const Icon(Icons.quiz,
                    color: AppTheme.quizzesColor),
              ),
              title: Text(quiz.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${quiz.subject} · ${quiz.questions.length} questions · ${quiz.coinValue} coins'
                    '${quiz.lessonId != null ? ' · Linked' : ' · Standalone'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manage questions
                  IconButton(
                    icon: const Icon(Icons.list_alt,
                        color: AppTheme.primary),
                    tooltip: 'Manage Questions',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminQuizQuestionsScreen(quiz: quiz),
                      ),
                    ).then((_) => _load()),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppTheme.textSecondary),
                    onPressed: () => _showForm(quiz: quiz),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppTheme.danger),
                    onPressed: () => _delete(quiz),
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