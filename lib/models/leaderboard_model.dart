import 'friend_model.dart';

class LeaderboardModel {
  final String id;
  final String childId;
  final int totalCoins;
  final int totalCorrect;
  final int score;
  final DateTime updatedAt;
  final ChildInfo? childInfo;

  LeaderboardModel({
    required this.id,
    required this.childId,
    required this.totalCoins,
    required this.totalCorrect,
    required this.score,
    required this.updatedAt,
    this.childInfo,
  });

  factory LeaderboardModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardModel(
      id: map['id'],
      childId: map['child_id'],
      totalCoins: map['total_coins'] ?? 0,
      totalCorrect: map['total_correct'] ?? 0,
      score: map['score'] ?? 0,
      updatedAt: DateTime.parse(map['updated_at']),
      childInfo: map['children'] != null
          ? ChildInfo.fromMap(map['children'])
          : null,
    );
  }
}
