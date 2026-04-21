import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../child/home_screen_shell.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final int coinsEarned;
  final String quizTitle;
  final bool isPracticeMode;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.coinsEarned,
    required this.quizTitle,
    this.isPracticeMode = false,
  });

  int get _stars {
    final ratio = score / total;
    if (ratio == 1.0) return 3;
    if (ratio >= 0.6) return 2;
    if (ratio >= 0.3) return 1;
    return 0;
  }

  String get _message {
    final ratio = score / total;
    if (ratio == 1.0) return 'Amazing! Perfect score! 🎉';
    if (ratio >= 0.8) return 'Great job! 🌟';
    if (ratio >= 0.6) return 'Good effort! Keep it up! 👍';
    if (ratio >= 0.3) return 'Keep practising! 💪';
    return 'Better luck next time! 🤗';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Practice mode banner
              if (isPracticeMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, color: AppTheme.accent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Practice Mode — no coins awarded',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const Icon(Icons.emoji_events, size: 80, color: AppTheme.accent),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPracticeMode ? 'Practice Complete!' : 'Quiz Completed!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    i < _stars ? Icons.star : Icons.star_border,
                    color: AppTheme.accent,
                    size: 48,
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Score + coins card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard('Score', '$score / $total', AppTheme.primary),
                    _statCard(
                      'Coins',
                      isPracticeMode ? '—' : '+$coinsEarned',
                      AppTheme.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChildDashboardScreen(),
                  ),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
