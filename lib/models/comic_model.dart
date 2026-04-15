class ComicModel {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String? coverUrl;
  final List<String> pages;
  final DateTime createdAt;

  ComicModel({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverUrl,
    this.pages = const [],
    required this.createdAt,
  });

  factory ComicModel.fromMap(Map<String, dynamic> map) {
    return ComicModel(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      description: map['description'],
      coverUrl: map['cover_url'],
      pages: map['pages'] != null
          ? List<String>.from(map['pages'])
          : [],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}