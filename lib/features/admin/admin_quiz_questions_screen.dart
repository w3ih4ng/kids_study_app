import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/quiz_image_service.dart';
import '../../core/services/quiz_service.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/quiz_model.dart';
import '../../core/widgets/app_snackbar.dart';

class AdminQuizQuestionsScreen extends StatefulWidget {
  final QuizModel quiz;
  const AdminQuizQuestionsScreen({super.key, required this.quiz});

  @override
  State<AdminQuizQuestionsScreen> createState() =>
      _AdminQuizQuestionsScreenState();
}

class _AdminQuizQuestionsScreenState
    extends State<AdminQuizQuestionsScreen> {
  late QuizModel _quiz;
  bool _isLoading = false;

  // Form controllers
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();

  // Single answer
  String _correctAnswer = 'a';

  // Multiple answer
  bool _isMultipleAnswer = false;
  List<String> _selectedCorrectAnswers = ['a'];

  // Image urls for form
  String? _questionImageUrl;
  String? _optionAImageUrl;
  String? _optionBImageUrl;
  String? _optionCImageUrl;
  String? _optionDImageUrl;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final quizzes = await QuizService.getQuizzes();
    final updated = quizzes.firstWhere((q) => q.id == _quiz.id);
    if (mounted) {
      setState(() {
        _quiz = updated;
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _correctAnswer = 'a';
    _isMultipleAnswer = false;
    _selectedCorrectAnswers = ['a'];
    _questionImageUrl = null;
    _optionAImageUrl = null;
    _optionBImageUrl = null;
    _optionCImageUrl = null;
    _optionDImageUrl = null;
  }

  Future<void> _uploadImage({
    required StateSetter setModalState,
    required String prefix,
    required Function(String url) onUploaded,
  }) async {
    final url = await QuizImageService.showSourcePicker(context);
    if (url != null) {
      setModalState(() => onUploaded(url));
    }
  }

  Widget _imageUploadButton({
    required String label,
    required String? imageUrl,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    if (imageUrl != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () => _showFullImage(imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 12),
            ),
          ),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_photo_alternate, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity),
            ),
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
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuestionForm(
      {QuizQuestionModel? question}) async {
    if (question != null) {
      _questionController.text = question.question;
      _optionAController.text = question.optionA;
      _optionBController.text = question.optionB;
      _optionCController.text = question.optionC;
      _optionDController.text = question.optionD;
      _correctAnswer = question.correctAnswer;
      _isMultipleAnswer = question.isMultipleAnswer;
      _selectedCorrectAnswers =
      question.isMultipleAnswer && question.correctAnswers.isNotEmpty
          ? List.from(question.correctAnswers)
          : [question.correctAnswer];
      _questionImageUrl = question.questionImageUrl;
      _optionAImageUrl = question.optionAImageUrl;
      _optionBImageUrl = question.optionBImageUrl;
      _optionCImageUrl = question.optionCImageUrl;
      _optionDImageUrl = question.optionDImageUrl;
    } else {
      _clearForm();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
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
                  question == null
                      ? 'Add Question'
                      : 'Edit Question',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── Question ────────────────────────────
                const Text('Question',
                    style:
                    TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                    'Enter question text (optional if image provided)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _imageUploadButton(
                  label: 'Add question image',
                  imageUrl: _questionImageUrl,
                  onTap: () => _uploadImage(
                    setModalState: setModalState,
                    prefix: 'question',
                    onUploaded: (url) => _questionImageUrl = url,
                  ),
                  onRemove: () => setModalState(
                          () => _questionImageUrl = null),
                ),
                const SizedBox(height: 16),

                // ── Multiple answer toggle ───────────────
                Container(
                  decoration: BoxDecoration(
                    color: _isMultipleAnswer
                        ? AppTheme.secondary
                        .withValues(alpha: 0.08)
                        : Theme.of(context)
                        .colorScheme
                        .surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isMultipleAnswer
                          ? AppTheme.secondary
                          .withValues(alpha: 0.4)
                          : Theme.of(context)
                          .colorScheme
                          .outline,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Multiple Correct Answers',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    subtitle: Text(
                      _isMultipleAnswer
                          ? 'Select all correct options below'
                          : 'Only one correct answer',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)),
                    ),
                    value: _isMultipleAnswer,
                    activeColor: AppTheme.secondary,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    onChanged: (val) => setModalState(() {
                      _isMultipleAnswer = val;
                      // Reset selections
                      _selectedCorrectAnswers = ['a'];
                      _correctAnswer = 'a';
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Options ─────────────────────────────
                const Text('Options',
                    style:
                    TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ...['a', 'b', 'c', 'd'].map((key) {
                  final controller = {
                    'a': _optionAController,
                    'b': _optionBController,
                    'c': _optionCController,
                    'd': _optionDController,
                  }[key]!;

                  final imageUrl = {
                    'a': _optionAImageUrl,
                    'b': _optionBImageUrl,
                    'c': _optionCImageUrl,
                    'd': _optionDImageUrl,
                  }[key];

                  // Correct state depends on mode
                  final isCorrect = _isMultipleAnswer
                      ? _selectedCorrectAnswers.contains(key)
                      : _correctAnswer == key;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppTheme.success
                          .withValues(alpha: 0.05)
                          : Theme.of(context)
                          .colorScheme
                          .surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect
                            ? AppTheme.success
                            : Theme.of(context)
                            .colorScheme
                            .outline,
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Correct answer selector
                            // Single = radio, Multiple = checkbox
                            GestureDetector(
                              onTap: () =>
                                  setModalState(() {
                                    if (_isMultipleAnswer) {
                                      if (_selectedCorrectAnswers
                                          .contains(key)) {
                                        // Don't allow deselecting all
                                        if (_selectedCorrectAnswers
                                            .length >
                                            1) {
                                          _selectedCorrectAnswers
                                              .remove(key);
                                        }
                                      } else {
                                        _selectedCorrectAnswers
                                            .add(key);
                                      }
                                    } else {
                                      _correctAnswer = key;
                                      _selectedCorrectAnswers = [
                                        key
                                      ];
                                    }
                                  }),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? AppTheme.success
                                      : Theme.of(context)
                                      .colorScheme
                                      .surface,
                                  shape: _isMultipleAnswer
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius:
                                  _isMultipleAnswer
                                      ? BorderRadius
                                      .circular(6)
                                      : null,
                                  border: Border.all(
                                    color: isCorrect
                                        ? AppTheme.success
                                        : Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                ),
                                child: Center(
                                  child: isCorrect
                                      ? Icon(
                                    _isMultipleAnswer
                                        ? Icons.check
                                        : Icons
                                        .circle,
                                    color: Colors.white,
                                    size: _isMultipleAnswer
                                        ? 16
                                        : 10,
                                  )
                                      : Text(
                                    key.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 12,
                                      color: Theme.of(
                                          context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText:
                                  'Option ${key.toUpperCase()} text (optional)',
                                  border:
                                  const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding:
                                  const EdgeInsets.all(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _imageUploadButton(
                          label:
                          'Add image for option ${key.toUpperCase()}',
                          imageUrl: imageUrl,
                          onTap: () => _uploadImage(
                            setModalState: setModalState,
                            prefix: 'option_$key',
                            onUploaded: (url) {
                              switch (key) {
                                case 'a':
                                  _optionAImageUrl = url;
                                  break;
                                case 'b':
                                  _optionBImageUrl = url;
                                  break;
                                case 'c':
                                  _optionCImageUrl = url;
                                  break;
                                case 'd':
                                  _optionDImageUrl = url;
                                  break;
                              }
                            },
                          ),
                          onRemove: () =>
                              setModalState(() {
                                switch (key) {
                                  case 'a':
                                    _optionAImageUrl = null;
                                    break;
                                  case 'b':
                                    _optionBImageUrl = null;
                                    break;
                                  case 'c':
                                    _optionCImageUrl = null;
                                    break;
                                  case 'd':
                                    _optionDImageUrl = null;
                                    break;
                                }
                              }),
                        ),
                      ],
                    ),
                  );
                }),

                // ── Correct answer summary ───────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                    AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.success, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isMultipleAnswer
                              ? 'Correct answers: ${_selectedCorrectAnswers.map((e) => e.toUpperCase()).join(', ')}'
                              : 'Correct answer: Option ${_correctAnswer.toUpperCase()}',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (_questionController.text.trim().isEmpty &&
                        _questionImageUrl == null) {
                      AppSnackbar.warning(context,
                          'Please enter a question or add an image.');
                      return;
                    }
                    if (_isMultipleAnswer &&
                        _selectedCorrectAnswers.length < 2) {
                      AppSnackbar.warning(context,
                          'Multiple answer mode requires at least 2 correct answers.');
                      return;
                    }
                    try {
                      final data = {
                        'question':
                        _questionController.text.trim(),
                        'question_image_url': _questionImageUrl,
                        'option_a':
                        _optionAController.text.trim(),
                        'option_a_image_url': _optionAImageUrl,
                        'option_b':
                        _optionBController.text.trim(),
                        'option_b_image_url': _optionBImageUrl,
                        'option_c':
                        _optionCController.text.trim(),
                        'option_c_image_url': _optionCImageUrl,
                        'option_d':
                        _optionDController.text.trim(),
                        'option_d_image_url': _optionDImageUrl,
                        'correct_answer': _isMultipleAnswer
                            ? _selectedCorrectAnswers.first
                            : _correctAnswer,
                        'is_multiple_answer': _isMultipleAnswer,
                        'correct_answers': _isMultipleAnswer
                            ? _selectedCorrectAnswers
                            : null,
                      };

                      if (question == null) {
                        await QuizService.addQuestion(
                          quizId: _quiz.id,
                          question:
                          _questionController.text.trim(),
                          questionImageUrl: _questionImageUrl,
                          optionA:
                          _optionAController.text.trim(),
                          optionAImageUrl: _optionAImageUrl,
                          optionB:
                          _optionBController.text.trim(),
                          optionBImageUrl: _optionBImageUrl,
                          optionC:
                          _optionCController.text.trim(),
                          optionCImageUrl: _optionCImageUrl,
                          optionD:
                          _optionDController.text.trim(),
                          optionDImageUrl: _optionDImageUrl,
                          correctAnswer: _isMultipleAnswer
                              ? _selectedCorrectAnswers.first
                              : _correctAnswer,
                          isMultipleAnswer: _isMultipleAnswer,
                          correctAnswers: _isMultipleAnswer
                              ? _selectedCorrectAnswers
                              : [],
                        );
                      } else {
                        await QuizService.updateQuestion(
                            question.id, data);
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        _reload();
                        AppSnackbar.success(
                          context,
                          question == null
                              ? 'Question added!'
                              : 'Question updated!',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.error(
                            context, 'Failed: ${e.toString()}');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(question == null
                      ? 'Add Question'
                      : 'Update Question'),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_quiz.questions.length} questions · ${_quiz.coinValue} coins total',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _quiz.questions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined,
                size: 72,
                color:
                cs.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No questions yet',
                style: TextStyle(
                    color: cs.onSurface
                        .withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showQuestionForm(),
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
            margin:
            const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme
                            .primary
                            .withValues(alpha: 0.1),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                AppTheme.primary,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            if (q.question
                                .isNotEmpty)
                              Text(q.question,
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .bold)),
                            if (q.questionImageUrl !=
                                null)
                              GestureDetector(
                                onTap: () =>
                                    _showFullImage(
                                        q.questionImageUrl!),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius
                                      .circular(8),
                                  child: Image.network(
                                    q.questionImageUrl!,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            // Multiple answer badge
                            if (q.isMultipleAnswer)
                              Padding(
                                padding:
                                const EdgeInsets
                                    .only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 8,
                                      vertical: 2),
                                  decoration:
                                  BoxDecoration(
                                    color: AppTheme
                                        .secondary
                                        .withValues(
                                        alpha:
                                        0.1),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                        8),
                                  ),
                                  child: const Text(
                                    'Multiple answers',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme
                                            .secondary,
                                        fontWeight:
                                        FontWeight
                                            .bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit,
                            color: AppTheme
                                .textSecondary,
                            size: 20),
                        onPressed: () =>
                            _showQuestionForm(
                                question: q),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.delete,
                            color: AppTheme.danger,
                            size: 20),
                        onPressed: () async {
                          try {
                            await QuizService
                                .deleteQuestion(q.id);
                            _reload();
                            if (mounted) {
                              AppSnackbar.success(
                                  context,
                                  'Question deleted.');
                            }
                          } catch (e) {
                            if (mounted) {
                              AppSnackbar.error(
                                  context,
                                  'Failed to delete question.');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Options
                  ...['a', 'b', 'c', 'd'].map((key) {
                    // Support both single and multiple
                    final isCorrect = q.isMultipleAnswer
                        ? q.correctAnswers.contains(key)
                        : q.correctAnswer == key;
                    final imageUrl =
                    q.optionImageUrl(key);
                    final text = q.optionText(key);

                    return Container(
                      margin: const EdgeInsets.only(
                          bottom: 4),
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppTheme.success
                            .withValues(alpha: 0.1)
                            : cs.surface,
                        borderRadius:
                        BorderRadius.circular(8),
                        border: Border.all(
                            color: isCorrect
                                ? AppTheme.success
                                : cs.outline),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${key.toUpperCase()}. ',
                            style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color: isCorrect
                                    ? AppTheme.success
                                    : cs.onSurface),
                          ),
                          Expanded(
                            child: imageUrl != null
                                ? GestureDetector(
                              onTap: () =>
                                  _showFullImage(
                                      imageUrl),
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                    4),
                                child:
                                Image.network(
                                  imageUrl,
                                  height: 40,
                                  width: 40,
                                  fit:
                                  BoxFit.cover,
                                ),
                              ),
                            )
                                : Text(
                              text,
                              overflow: TextOverflow
                                  .ellipsis,
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                                Icons.check_circle,
                                color: AppTheme.success,
                                size: 16),
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
        onPressed: () => _showQuestionForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}