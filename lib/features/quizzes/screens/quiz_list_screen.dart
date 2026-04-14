import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/services/quiz_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/quiz_model.dart';
import 'quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<QuizModel> _mathQuizzes = [];
  List<QuizModel> _englishQuizzes = [];
  // Map of quizId -> first attempt result (null = not attempted)
  Map<String, Map<String, dynamic>?> _attemptMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final childId = context.read<ChildProvider>().activeChild?.id ?? '';
    final math = await QuizService.getQuizzes(subject: 'Math');
    final english = await QuizService.getQuizzes(subject: 'English');

    // Check attempt status for all quizzes
    final allQuizzes = [...math, ...english];
    final Map<String, Map<String, dynamic>?> attempts = {};
    for (final quiz in allQuizzes) {
      attempts[quiz.id] = await QuizService.getFirstAttempt(
        childId: childId,
        quizId: quiz.id,
      );
    }

    if (mounted) {
      setState(() {
        _mathQuizzes = math;
        _englishQuizzes = english;
        _attemptMap = attempts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.quizzesColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [Tab(text: 'Math'), Tab(text: 'English')],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : TabBarView(
            controller: _tabController,
            children: [
              _buildQuizList(_mathQuizzes),
              _buildQuizList(_englishQuizzes),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizList(List<QuizModel> quizzes) {
    if (quizzes.isEmpty) {
      return const EmptyStateWidget(
        message: 'No quizzes available yet.',
        icon: Icons.quiz_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (_, i) => _quizCard(quizzes[i]),
    );
  }

  Widget _quizCard(QuizModel quiz) {
    final hasQuestions = quiz.questions.isNotEmpty;
    final firstAttempt = _attemptMap[quiz.id];
    final attempted = firstAttempt != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: attempted
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.quizzesColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    attempted ? Icons.check_circle : Icons.quiz,
                    color: attempted
                        ? AppTheme.success
                        : AppTheme.quizzesColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quiz.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '${quiz.questions.length} questions · ${quiz.coinValue} coins',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      // Show first attempt score if attempted
                      if (attempted) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Best score: ${firstAttempt!['score']}/${firstAttempt['total']} · +${firstAttempt['coins_earned']} coins earned',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // First attempt / retake button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasQuestions
                        ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          quiz: quiz,
                          isPracticeMode: attempted,
                        ),
                      ),
                    ).then((_) => _load())
                        : null,
                    icon: Icon(attempted
                        ? Icons.replay
                        : Icons.play_arrow),
                    label: Text(
                      !hasQuestions
                          ? 'No questions yet'
                          : attempted
                          ? 'Practice Again'
                          : 'Start Quiz',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: attempted
                          ? AppTheme.textSecondary
                          : AppTheme.quizzesColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            // Practice mode notice
            if (attempted)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Practice mode — no coins awarded for retakes',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}