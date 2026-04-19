class LessonModel {
  final String id;
  final String title;
  final String subject;
  final String difficulty;
  final String type;
  final String? contentUrl;
  final String? description;
  final String ageLevel;
  final DateTime createdAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.type,
    this.contentUrl,
    this.description,
    this.ageLevel = '6+',
    required this.createdAt,
  });

  // Auto-extract YouTube thumbnail
  String? get thumbnailUrl {
    if (type == 'youtube' && contentUrl != null) {
      final uri = Uri.tryParse(contentUrl!);
      String? videoId;
      if (uri != null) {
        if (uri.host.contains('youtu.be')) {
          videoId = uri.pathSegments.isNotEmpty
              ? uri.pathSegments.first
              : null;
        } else {
          videoId = uri.queryParameters['v'];
        }
      }
      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }
    if (type == 'image') return contentUrl;
    return null;
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      difficulty: map['difficulty'] ?? 'Easy',
      type: map['type'] ?? 'youtube',
      contentUrl: map['content_url'],
      description: map['description'],
      ageLevel: map['age_level'] ?? '6+',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}