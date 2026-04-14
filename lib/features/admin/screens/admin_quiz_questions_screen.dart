import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/quiz_model.dart';

class AdminQuizQuestionsScreen extends StatefulWidget {
  final QuizModel quiz;
  const AdminQuizQuestionsScreen({super.key, required this.quiz});

  @override
  State<AdminQuizQuestionsScreen> createState() =>
      _AdminQuizQuestionsScreenState();
}

class _AdminQuizQuestionsScreenState extends State<AdminQuizQuestionsScreen> {
  late QuizModel _quiz;
  bool _isLoading = false;

  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  String _correctAnswer = 'a';

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final quizzes = await QuizService.getQuizzes();
    final updated = quizzes.firstWhere((q) => q.id == _quiz.id);
    if (mounted) setState(() { _quiz = updated; _isLoading = false; });
  }

  void _clearForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswer = 'a';
  }

  Future<void> _showAddQuestion() async {
    _clearForm();
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
                const Text('Add Question',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ...[
                  ('A', _optionAController),
                  ('B', _optionBController),
                  ('C', _optionCController),
                  ('D', _optionDController),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: e.$2,
                    decoration: InputDecoration(
                      labelText: 'Option ${e.$1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                )),
                // Correct answer selector
                const Text('Correct Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: ['a', 'b', 'c', 'd'].map((key) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setModalState(() => _correctAnswer = key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _correctAnswer == key
                                ? AppTheme.primary
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _correctAnswer == key
                                    ? AppTheme.primary
                                    : AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              key.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correctAnswer == key
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_questionController.text.trim().isEmpty) return;
                    await QuizService.addQuestion(
                      quizId: _quiz.id,
                      question: _questionController.text.trim(),
                      optionA: _optionAController.text.trim(),
                      optionB: _optionBController.text.trim(),
                      optionC: _optionCController.text.trim(),
                      optionD: _optionDController.text.trim(),
                      correctAnswer: _correctAnswer,
                    );
                    if (context.mounted) Navigator.pop(context);
                    _reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add Question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditQuestion(QuizQuestionModel question) async {
    _questionController.text = question.question;
    _optionAController.text = question.optionA;
    _optionBController.text = question.optionB;
    _optionCController.text = question.optionC;
    _optionDController.text = question.optionD;
    _correctAnswer = question.correctAnswer;

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
                const Text('Edit Question',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ...[
                  ('A', _optionAController),
                  ('B', _optionBController),
                  ('C', _optionCController),
                  ('D', _optionDController),
                ].map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: e.$2,
                    decoration: InputDecoration(
                      labelText: 'Option ${e.$1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                )),
                const Text('Correct Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: ['a', 'b', 'c', 'd'].map((key) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setModalState(() => _correctAnswer = key),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _correctAnswer == key
                                ? AppTheme.primary
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: _correctAnswer == key
                                    ? AppTheme.primary
                                    : AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              key.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _correctAnswer == key
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await QuizService.updateQuestion(question.id, {
                      'question': _questionController.text.trim(),
                      'option_a': _optionAController.text.trim(),
                      'option_b': _optionBController.text.trim(),
                      'option_c': _optionCController.text.trim(),
                      'option_d': _optionDController.text.trim(),
                      'correct_answer': _correctAnswer,
                    });
                    if (context.mounted) Navigator.pop(context);
                    _reload();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Update Question'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_quiz.questions.length} questions · ${_quiz.coinValue} coins total',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _quiz.questions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined,
                size: 72, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            const Text('No questions yet',
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showAddQuestion,
              child: const Text('Add Question'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quiz.questions.length,
        itemBuilder: (_, i) {
          final q = _quiz.questions[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(q.question,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      // Edit button — ADD THIS
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme.textSecondary, size: 20),
                        onPressed: () => _showEditQuestion(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.danger, size: 20),
                        onPressed: () async {
                          await QuizService.deleteQuestion(q.id);
                          _reload();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...['a', 'b', 'c', 'd'].map((key) {
                    final isCorrect = q.correctAnswer == key;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: isCorrect
                                ? AppTheme.success
                                : AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${key.toUpperCase()}. ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? AppTheme.success
                                    : AppTheme.textPrimary),
                          ),
                          Text(q.optionText(key)),
                          if (isCorrect) ...[
                            const Spacer(),
                            const Icon(Icons.check_circle,
                                color: AppTheme.success, size: 16),
                          ]
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestion,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}