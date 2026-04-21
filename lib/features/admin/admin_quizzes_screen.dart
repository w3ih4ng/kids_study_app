import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/lesson_service.dart';
import '../../core/services/quiz_service.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/lesson_model.dart';
import '../../models/quiz_model.dart';
import 'admin_quiz_questions_screen.dart';
import '../../core/widgets/app_snackbar.dart';

class AdminQuizzesScreen extends StatefulWidget {
  const AdminQuizzesScreen({super.key});

  @override
  State<AdminQuizzesScreen> createState() => _AdminQuizzesScreenState();
}

class _AdminQuizzesScreenState extends State<AdminQuizzesScreen> {
  List<QuizModel> _quizzes = [];
  List<LessonModel> _lessons = [];
  bool _isLoading = true;
  String? _expandedQuizId; // tracks which card is expanded

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
                  quiz == null ? 'Add New Quiz' : 'Edit Quiz',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Quiz Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                DropdownButtonFormField<String?>(
                  initialValue: _selectedLessonId,
                  decoration: const InputDecoration(
                    labelText: 'Linked Lesson (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Standalone quiz'),
                    ),
                    ..._lessons.map(
                      (l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.title)),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => _selectedLessonId = v),
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
                const Text(
                  'Thumbnail (optional)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: _isUploadingThumb
                        ? const Center(child: CircularProgressIndicator())
                        : _thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _thumbnailUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to add thumbnail',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
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
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.trim().isEmpty) {
                      AppSnackbar.warning(
                        context,
                        'Please enter a quiz title.',
                      );
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
                        if (context.mounted) {
                          AppSnackbar.success(
                            context,
                            'Quiz created successfully!',
                          );
                        }
                      } else {
                        await QuizService.updateQuiz(quiz.id, {
                          'title': _titleController.text.trim(),
                          'subject': _selectedSubject,
                          'lesson_id': _selectedLessonId,
                          'coin_value':
                              int.tryParse(_coinController.text) ?? 100,
                          'age_level': _selectedAgeLevel,
                          'thumbnail_url': _thumbnailUrl,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        if (context.mounted) {
                          AppSnackbar.success(
                            context,
                            'Quiz updated successfully!',
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
        content: Text(
          'Delete "${quiz.title}"? All questions will also be deleted.',
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Quiz Thumbnail',
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
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setModalState(() => _isUploadingThumb = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName =
          'quiz_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('quizzes')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                final isExpanded = _expandedQuizId == quiz.id;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpanded ? AppTheme.primary : cs.outline,
                      width: isExpanded ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Main row — always visible ──
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _expandedQuizId = isExpanded ? null : quiz.id;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Icon
                              quiz.thumbnailUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.network(
                                        quiz.thumbnailUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            CircleAvatar(
                                              backgroundColor: AppTheme
                                                  .quizzesColor
                                                  .withValues(alpha: 0.15),
                                              child: const Icon(
                                                Icons.quiz,
                                                color: AppTheme.quizzesColor,
                                              ),
                                            ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      backgroundColor: AppTheme.quizzesColor
                                          .withValues(alpha: 0.15),
                                      child: const Icon(
                                        Icons.quiz,
                                        color: AppTheme.quizzesColor,
                                      ),
                                    ),
                              const SizedBox(width: 12),

                              // Title + subject badge
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quiz.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${quiz.subject} · ${quiz.questions.length} questions · ${quiz.coinValue} coins',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Expanded section ───────────
                      if (isExpanded)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.quizzesColor.withValues(
                              alpha: 0.04,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                            border: Border(top: BorderSide(color: cs.outline)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _chip(
                                    Icons.child_care,
                                    quiz.ageLevel,
                                    AppTheme.secondary,
                                  ),
                                  _chip(
                                    Icons.monetization_on,
                                    '${quiz.coinValue} coins',
                                    AppTheme.accent,
                                  ),
                                  _chip(
                                    quiz.lessonId != null
                                        ? Icons.link
                                        : Icons.link_off,
                                    quiz.lessonId != null
                                        ? 'Linked to lesson'
                                        : 'Standalone',
                                    quiz.lessonId != null
                                        ? AppTheme.success
                                        : AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Manage questions button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AdminQuizQuestionsScreen(quiz: quiz),
                                    ),
                                  ).then((_) => _load()),
                                  icon: const Icon(Icons.list_alt),
                                  label: Text(
                                    'Manage Questions (${quiz.questions.length})',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.quizzesColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Edit + Delete row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showForm(quiz: quiz),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit Quiz'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.textSecondary,
                                        side: const BorderSide(
                                          color: AppTheme.textSecondary,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _delete(quiz),
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.danger,
                                        side: const BorderSide(
                                          color: AppTheme.danger,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
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

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
