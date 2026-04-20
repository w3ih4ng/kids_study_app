import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/providers/child_provider.dart';
import '../../core/services/quiz_service.dart';
import '../../models/child_model.dart';
import '../../models/quiz_model.dart';
import 'quiz_result_screen.dart';
import 'dart:math';

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
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Shuffle questions on start
    _questions = List.from(widget.quiz.questions)..shuffle(Random());
  }

  QuizQuestionModel get _currentQuestion => _questions[_currentIndex];

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      if (answer == _currentQuestion.correctAnswer) _score++;
    });
  }

  Future<void> _next() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      // Quiz complete
      int coinsEarned = 0;

      if (!widget.isPracticeMode) {
        final child = context.read<ChildProvider>().activeChild!;
        final result = await QuizService.submitResult(
          childId: child.id,
          quizId: widget.quiz.id,
          score: _score,
          total: _questions.length,
          quizCoinValue: widget.quiz.coinValue,
        );
        coinsEarned = result.coinsEarned;

        // Update coins in provider
        if (result.isFirstAttempt && coinsEarned > 0) {
          final updatedChild = ChildModel(
            id: child.id,
            parentId: child.parentId,
            nickname: child.nickname,
            avatarUrl: child.avatarUrl,
            coins: child.coins + coinsEarned,
          );
          if (mounted) {
            context.read<ChildProvider>().setActiveChild(updatedChild);
          }
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              score: _score,
              total: _questions.length,
              coinsEarned: coinsEarned,
              quizTitle: widget.quiz.title,
              isPracticeMode: widget.isPracticeMode,
            ),
          ),
        );
      }
    }
  }

  Color _optionColor(String key) {
    if (!_answered) return AppTheme.surface;
    if (key == _currentQuestion.correctAnswer) return AppTheme.success;
    if (key == _selectedAnswer) return AppTheme.danger;
    return AppTheme.surface;
  }

  Color _optionTextColor(String key) {
    if (!_answered) return AppTheme.textPrimary;
    if (key == _currentQuestion.correctAnswer) return Colors.white;
    if (key == _selectedAnswer) return Colors.white;
    return AppTheme.textSecondary;
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
              child: Image.network(
                url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
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

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        // Practice mode banner
        bottom: widget.isPracticeMode
            ? PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Container(
            color: AppTheme.accent.withValues(alpha:0.2),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 14, color: Colors.white70),
                SizedBox(width: 4),
                Text('Practice Mode — no coins awarded',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        )
            : PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            valueColor:
            const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isPracticeMode)
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.border,
                valueColor:
                const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            const SizedBox(height: 12),
            Text(
              'Question ${_currentIndex + 1} of $total',
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentQuestion.question.isNotEmpty)
                    Text(
                      _currentQuestion.question,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  if (_currentQuestion.questionImageUrl != null) ...[
                    if (_currentQuestion.question.isNotEmpty)
                      const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _showFullImage(
                          _currentQuestion.questionImageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _currentQuestion.questionImageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...['a', 'b', 'c', 'd'].map((key) {
              final imageUrl = _currentQuestion.optionImageUrl(key);
              final text = _currentQuestion.optionText(key);

              return GestureDetector(
                onTap: () => _selectAnswer(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _optionColor(key),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primary.withValues(alpha:0.1),
                        child: Text(key.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _optionTextColor(key),
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: imageUrl != null
                            ? GestureDetector(
                          onTap: () => _showFullImage(imageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : Text(
                          text,
                          style: TextStyle(
                            color: _optionTextColor(key),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_answered && key == _currentQuestion.correctAnswer)
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                      if (_answered &&
                          key == _selectedAnswer &&
                          key != _currentQuestion.correctAnswer)
                        const Icon(Icons.cancel,
                            color: Colors.white, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            if (_answered)
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < total - 1
                      ? 'Next Question'
                      : 'Finish Quiz',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}