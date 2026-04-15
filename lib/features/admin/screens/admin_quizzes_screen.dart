import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/lesson_model.dart';
import '../../../models/quiz_model.dart';
import 'admin_quiz_questions_screen.dart';
import '../../../core/services/notification_service.dart';

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
    } else {
      _titleController.clear();
      _coinController.text = '100';
      _selectedSubject = 'Math';
      _selectedLessonId = null;
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
                // Optional lesson link
                DropdownButtonFormField<String?>(
                  value: _selectedLessonId,
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
                    if (_titleController.text.trim().isEmpty) return;
                    if (quiz == null) {
                      await QuizService.createQuiz(
                        title: _titleController.text.trim(),
                        subject: _selectedSubject,
                        lessonId: _selectedLessonId,
                        coinValue:
                        int.tryParse(_coinController.text) ?? 100,
                      );
                      if (context.mounted) Navigator.pop(context);
                      _load();
                      await NotificationService.notifyAll(
                        title: '📚 New Lesson Available!',
                        body: '${_titleController.text.trim()} has been added. Check it out!',
                      );
                    } else {
                      await QuizService.updateQuiz(quiz.id, {
                        'title': _titleController.text.trim(),
                        'subject': _selectedSubject,
                        'lesson_id': _selectedLessonId,
                        'coin_value':
                        int.tryParse(_coinController.text) ?? 100,
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
        content: Text('Delete "${quiz.title}"?'),
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
      await QuizService.deleteQuiz(quiz.id);
      _load();
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
                AppTheme.quizzesColor.withOpacity(0.2),
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