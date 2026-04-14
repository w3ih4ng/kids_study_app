import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/lesson_service.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/lesson_model.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LessonModel> _mathLessons = [];
  List<LessonModel> _englishLessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final math = await LessonService.getLessons(subject: 'Math');
    final english = await LessonService.getLessons(subject: 'English');
    if (mounted) {
      setState(() {
        _mathLessons = math;
        _englishLessons = english;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar for Math / English
        Container(
          color: AppTheme.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Math'),
              Tab(text: 'English'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : TabBarView(
            controller: _tabController,
            children: [
              _buildLessonList(_mathLessons),
              _buildLessonList(_englishLessons),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonList(List<LessonModel> lessons) {
    if (lessons.isEmpty) {
      return const EmptyStateWidget(
        message: 'No lessons available yet.',
        icon: Icons.play_lesson_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (_, i) => _lessonCard(lessons[i]),
    );
  }

  Widget _lessonCard(LessonModel lesson) {
    final color = lesson.subject == 'Math'
        ? AppTheme.lessonsColor
        : AppTheme.quizzesColor;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  lesson.type == 'youtube' ? Icons.play_circle : Icons.image,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (lesson.description != null)
                      Text(lesson.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _tag(lesson.difficulty, _difficultyColor(lesson.difficulty)),
                        const SizedBox(width: 8),
                        _tag(lesson.subject, color),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy': return AppTheme.success;
      case 'Medium': return AppTheme.accent;
      case 'Hard': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}