import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/lesson_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final LessonModel lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.lesson.type == 'youtube' &&
        widget.lesson.contentUrl != null) {
      final videoId =
      YoutubePlayer.convertUrlToId(widget.lesson.contentUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final color = lesson.subject == 'Math'
        ? AppTheme.lessonsColor
        : AppTheme.quizzesColor;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video or image
            if (lesson.type == 'youtube' && _youtubeController != null)
              YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
              )
            else if (lesson.type == 'image' && lesson.contentUrl != null)
              Image.network(
                lesson.contentUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: color.withOpacity(0.1),
                  child: Icon(Icons.broken_image, color: color, size: 48),
                ),
              )
            else
              Container(
                height: 200,
                color: color.withOpacity(0.1),
                child: Center(
                  child: Icon(Icons.play_lesson, color: color, size: 64),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // Tags row
                  Row(
                    children: [
                      _tag(lesson.subject, color),
                      const SizedBox(width: 8),
                      _tag(lesson.difficulty, _difficultyColor(lesson.difficulty)),
                      const SizedBox(width: 8),
                    ],
                  ),
                  if (lesson.description != null) ...[
                    const SizedBox(height: 20),
                    const Text('About this lesson',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(lesson.description!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5)),
                  ],
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }
}