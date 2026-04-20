import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/services/lesson_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../models/lesson_model.dart';
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
  String _selectedAge = 'All';
  bool _isLoading = true;

  final List<String> _ageLevels = ['All', '4+', '5+', '6+', '7+', '8+'];

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

  List<LessonModel> _filtered(List<LessonModel> lessons) {
    if (_selectedAge == 'All') return lessons;
    return lessons.where((l) => l.ageLevel == _selectedAge).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.lessonsColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [Tab(text: 'Math'), Tab(text: 'English')],
          ),
        ),
        Container(
          color: AppTheme.lessonsColor.withValues(alpha:0.06),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            ? AppTheme.lessonsColor
                            : AppTheme.lessonsColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.lessonsColor
                              : AppTheme.lessonsColor.withValues(alpha:0.3),
                        ),
                      ),
                      child: Text(
                        age == 'All' ? 'All Ages' : '$age yrs',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppTheme.lessonsColor,
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
              _buildGrid(_filtered(_mathLessons)),
              _buildGrid(_filtered(_englishLessons)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<LessonModel> lessons) {
    if (lessons.isEmpty) {
      return const EmptyStateWidget(
        message: 'No lessons available.',
        icon: Icons.play_lesson_outlined,
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: lessons.length,
      itemBuilder: (_, i) => _lessonCard(lessons[i]),
    );
  }

  Widget _lessonCard(LessonModel lesson) {
    final cs = Theme.of(context).colorScheme;
    final color = lesson.subject == 'Math'
        ? AppTheme.lessonsColor
        : AppTheme.quizzesColor;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => LessonDetailScreen(lesson: lesson)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: lesson.thumbnailUrl != null
                    ? Image.network(
                  lesson.thumbnailUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _placeholderThumb(color),
                )
                    : _placeholderThumb(color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _badge(lesson.difficulty,
                            _difficultyColor(lesson.difficulty)),
                        _badge(lesson.ageLevel, AppTheme.secondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb(Color color) {
    return Container(
      color: color.withValues(alpha:0.12),
      child: Center(
        child: Icon(Icons.play_lesson,
            color: color.withValues(alpha:0.5), size: 36),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':   return AppTheme.success;
      case 'Medium': return AppTheme.accent;
      case 'Hard':   return AppTheme.danger;
      default:       return AppTheme.textSecondary;
    }
  }
}