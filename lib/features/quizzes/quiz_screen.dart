import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../models/quiz_model.dart';
import '../../core/services/child_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final QuizModel quiz;
  final bool isPracticeMode;

  const QuizScreen({
    super.key,
    required this.quiz,
    this.isPracticeMode = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestionModel> _questions;
  int _currentIndex = 0;

  // Selection state
  List<String> _selectedOptions = []; // supports multiple
  bool _isConfirmed = false;
  bool _showNext = false;
  int _correctCount = 0;

  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    // Shuffle questions
    _questions = List.from(widget.quiz.questions)..shuffle(Random());
  }

  QuizQuestionModel get _current => _questions[_currentIndex];

  bool get _isCorrect {
    final correct = _current.allCorrectAnswers.toSet();
    final selected = _selectedOptions.toSet();
    return correct.length == selected.length && correct.containsAll(selected);
  }

  void _selectOption(String option) {
    if (_isConfirmed) return; // locked after confirm
    setState(() {
      if (_current.isMultipleAnswer) {
        // Toggle for multiple
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
      } else {
        // Replace for single
        _selectedOptions = [option];
      }
    });
  }

  Future<void> _confirmAnswer() async {
    if (_selectedOptions.isEmpty) {
      AppSnackbar.warning(
        context,
        _current.isMultipleAnswer
            ? 'Please select at least one answer.'
            : 'Please select an answer.',
      );
      return;
    }

    setState(() => _isConfirmed = true);

    if (_isCorrect) _correctCount++;

    // 1 second delay then show Next button
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _showNext = true);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptions = [];
        _isConfirmed = false;
        _showNext = false;
      });
    } else {
      if (_isFinishing) return;
      _isFinishing = true;
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final child = context.read<ChildProvider>().activeChild!;
    final total = _questions.length;

    int coinsEarned = 0;
    try {
      if (!widget.isPracticeMode) {
        final result = await QuizService.submitResult(
          childId: child.id,
          quizId: widget.quiz.id,
          score: _correctCount,
          total: total,
          quizCoinValue: widget.quiz.coinValue,
        );
        coinsEarned = result.coinsEarned;

        // Refresh coins badge
        final updatedChildren = await ChildService.getChildren();
        final updatedChild = updatedChildren.firstWhere(
          (c) => c.id == child.id,
          orElse: () => child,
        );
        if (mounted) {
          context.read<ChildProvider>().setActiveChild(updatedChild);
        }
      }
    } catch (e) {
      debugPrint('Quiz finish error: $e');
      // Still navigate to result even if coins fail
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            quizTitle: widget.quiz.title,
            score: _correctCount,
            total: total,
            coinsEarned: coinsEarned,
            isPracticeMode: widget.isPracticeMode,
          ),
        ),
      );
    }
  }

  // Option color based on state
  Color _optionColor(String option) {
    final isSelected = _selectedOptions.contains(option);
    final isCorrect = _current.allCorrectAnswers.contains(option);

    if (!_isConfirmed) {
      return isSelected
          ? AppTheme.primary.withValues(alpha: 0.15)
          : Theme.of(context).colorScheme.surface;
    }

    // After confirm
    if (isCorrect) return AppTheme.success.withValues(alpha: 0.15);
    if (isSelected && !isCorrect) {
      return AppTheme.danger.withValues(alpha: 0.15);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _optionBorderColor(String option) {
    final isSelected = _selectedOptions.contains(option);
    final isCorrect = _current.allCorrectAnswers.contains(option);

    if (!_isConfirmed) {
      return isSelected
          ? AppTheme.primary
          : Theme.of(context).colorScheme.outline;
    }

    if (isCorrect) return AppTheme.success;
    if (isSelected && !isCorrect) return AppTheme.danger;
    return Theme.of(context).colorScheme.outline;
  }

  Widget? _optionTrailing(String option) {
    if (!_isConfirmed) {
      // Show checkbox or radio
      if (_current.isMultipleAnswer) {
        return _selectedOptions.contains(option)
            ? const Icon(Icons.check_box, color: AppTheme.primary)
            : const Icon(
                Icons.check_box_outline_blank,
                color: AppTheme.textSecondary,
              );
      } else {
        return _selectedOptions.contains(option)
            ? const Icon(Icons.radio_button_checked, color: AppTheme.primary)
            : const Icon(
                Icons.radio_button_unchecked,
                color: AppTheme.textSecondary,
              );
      }
    }

    final isCorrect = _current.allCorrectAnswers.contains(option);
    final isSelected = _selectedOptions.contains(option);

    if (isCorrect) {
      return const Icon(Icons.check_circle, color: AppTheme.success);
    }
    if (isSelected && !isCorrect) {
      return const Icon(Icons.cancel, color: AppTheme.danger);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Practice mode banner
                    if (widget.isPracticeMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              color: AppTheme.accent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Practice Mode — No coins',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Question number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of ${_questions.length}',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        if (_current.isMultipleAnswer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Multiple answers',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question image
                    if (_current.questionImageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _current.questionImageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Question text
                    Text(
                      _current.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ..._buildOptions(cs),

                    // Feedback message after confirm
                    if (_isConfirmed) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCorrect
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : AppTheme.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCorrect ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect
                                  ? AppTheme.success
                                  : AppTheme.danger,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _isCorrect
                                    ? 'Correct! Well done! 🎉'
                                    : 'Incorrect.',
                                style: TextStyle(
                                  color: _isCorrect
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outline)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: !_isConfirmed
                    ? ElevatedButton.icon(
                        onPressed: _selectedOptions.isEmpty
                            ? null
                            : _confirmAnswer,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Confirm Answer',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: cs.outline,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : !_showNext
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCorrect
                              ? AppTheme.success
                              : AppTheme.danger,
                          disabledBackgroundColor: _isCorrect
                              ? AppTheme.success.withValues(alpha: 0.6)
                              : AppTheme.danger.withValues(alpha: 0.6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _nextQuestion,
                        icon: Icon(
                          _currentIndex < _questions.length - 1
                              ? Icons.arrow_forward
                              : Icons.flag,
                        ),
                        label: Text(
                          _currentIndex < _questions.length - 1
                              ? 'Next Question'
                              : 'See Results',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptions(ColorScheme cs) {
    final options = [
      ('a', _current.optionA, _current.optionAImageUrl),
      ('b', _current.optionB, _current.optionBImageUrl),
      ('c', _current.optionC, _current.optionCImageUrl),
      ('d', _current.optionD, _current.optionDImageUrl),
    ];

    return options.map((opt) {
      final key = opt.$1;
      final text = opt.$2;
      final imageUrl = opt.$3;

      return GestureDetector(
        onTap: () => _selectOption(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _optionColor(key),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _optionBorderColor(key),
              width:
                  _selectedOptions.contains(key) ||
                      (_isConfirmed && _current.allCorrectAnswers.contains(key))
                  ? 2
                  : 1,
            ),
          ),
          child: Row(
            children: [
              // Option label circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _optionBorderColor(key).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    key.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _optionBorderColor(key),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (text.isNotEmpty)
                      Text(text, style: const TextStyle(fontSize: 15)),
                    if (imageUrl != null) ...[
                      if (text.isNotEmpty) const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_optionTrailing(key) != null) ...[
                const SizedBox(width: 8),
                _optionTrailing(key)!,
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
