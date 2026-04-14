class LessonModel {
  final String id;
  final String title;
  final String subject;
  final String difficulty;
  final String type;
  final String? contentUrl;
  final String? description;
  final DateTime createdAt;

  LessonModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.type,
    this.contentUrl,
    this.description,
    required this.createdAt,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      difficulty: map['difficulty'] ?? 'Easy',
      type: map['type'] ?? 'youtube',
      contentUrl: map['content_url'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}