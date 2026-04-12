class ChildModel {
  final String id;
  final String parentId;
  final String nickname;
  final String? avatarUrl;
  final int coins;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.nickname,
    this.avatarUrl,
    this.coins = 0,
  });

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'],
      parentId: map['parent_id'],
      nickname: map['nickname'],
      avatarUrl: map['avatar_url'],
      coins: map['coins'] ?? 0,
    );
  }
}