import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/child_provider.dart';
import '../../../../core/services/lesson_service.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../models/lesson_model.dart';
import '../../../../models/quiz_model.dart';
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
  Map<String, Map<String, dynamic>?> _attemptMap = {};
  Map<String, LessonModel> _lessonMap = {};
  String _selectedAge = 'All';
  bool _isLoading = true;

  final List<String> _ageLevels = ['All', '4+', '5+', '6+', '7+', '8+'];
  String? _expandedQuizId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final childId =
        context.read<ChildProvider>().activeChild?.id ?? '';
    final math = await QuizService.getQuizzes(subject: 'Math');
    final english = await QuizService.getQuizzes(subject: 'English');
    final allLessons = await LessonService.getLessons();

    final Map<String, LessonModel> lessonMap = {
      for (final l in allLessons) l.id: l
    };

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
        _lessonMap = lessonMap;
        _isLoading = false;
      });
    }
  }

  List<QuizModel> _filtered(List<QuizModel> quizzes) {
    if (_selectedAge == 'All') return quizzes;
    return quizzes.where((q) => q.ageLevel == _selectedAge).toList();
  }

  String? _getQuizThumbnail(QuizModel quiz) {
    if (quiz.thumbnailUrl != null) return quiz.thumbnailUrl;
    if (quiz.lessonId != null) {
      final lesson = _lessonMap[quiz.lessonId];
      return lesson?.thumbnailUrl;
    }
    return null;
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
        Container(
          color: AppTheme.quizzesColor.withOpacity(0.06),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ageLevels.map((age) {
                final selected = _selectedAge == age;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAge = age),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.quizzesColor
                            : AppTheme.quizzesColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.quizzesColor
                              : AppTheme.quizzesColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        age == 'All' ? 'All Ages' : '$age yrs',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppTheme.quizzesColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_filtered(_mathQuizzes)),
              _buildList(_filtered(_englishQuizzes)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<QuizModel> quizzes) {
    if (quizzes.isEmpty) {
      return const EmptyStateWidget(
        message: 'No quizzes available.',
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
    final cs = Theme.of(context).colorScheme;
    final attempted = _attemptMap[quiz.id] != null;
    final firstAttempt = _attemptMap[quiz.id];
    final hasQuestions = quiz.questions.isNotEmpty;
    final isExpanded = _expandedQuizId == quiz.id;
    final thumbUrl = _getQuizThumbnail(quiz);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: attempted
              ? AppTheme.success.withOpacity(0.5)
              : cs.outline,
          width: attempted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() =>
            _expandedQuizId = isExpanded ? null : quiz.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: thumbUrl != null
                          ? Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _defaultThumb(),
                      )
                          : _defaultThumb(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            _badge(quiz.ageLevel, AppTheme.secondary),
                            _badge(quiz.subject, AppTheme.quizzesColor),
                            if (attempted)
                              _badge('Done ✓', AppTheme.success),
                          ],
                        ),
                        if (attempted && firstAttempt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Best: ${firstAttempt['score']}/${firstAttempt['total']}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: cs.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.quizzesColor.withOpacity(0.04),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: cs.outline),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(Icons.quiz_outlined,
                          '${quiz.questions.length}', 'Questions', cs),
                      Container(
                          width: 1, height: 32, color: cs.outline),
                      _statItem(Icons.monetization_on,
                          '${quiz.coinValue}', 'Coins', cs),
                      Container(
                          width: 1, height: 32, color: cs.outline),
                      _statItem(Icons.child_care,
                          quiz.ageLevel, 'Age', cs),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
                      icon: Icon(
                          attempted ? Icons.replay : Icons.play_arrow),
                      label: Text(
                        !hasQuestions
                            ? 'No questions yet'
                            : attempted
                            ? 'Practice Again'
                            : 'Start Quiz',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: attempted
                            ? cs.onSurface.withOpacity(0.4)
                            : AppTheme.quizzesColor,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (attempted)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Practice mode — no coins for retakes',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withOpacity(0.6)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultThumb() {
    return Image.asset(
      'assets/images/default_quiz.jpg',
      fit: BoxFit.cover,
      width: 72,
      height: 72,
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, ColorScheme cs) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.quizzesColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(
                color: cs.onSurface.withOpacity(0.6), fontSize: 11)),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold)),
    );
  }
}