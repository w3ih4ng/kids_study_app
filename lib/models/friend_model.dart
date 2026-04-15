class FriendModel {
  final String id;
  final String childId;
  final String friendId;
  final bool isBestFriend;
  final DateTime createdAt;
  final ChildInfo? friendInfo;

  FriendModel({
    required this.id,
    required this.childId,
    required this.friendId,
    this.isBestFriend = false,
    required this.createdAt,
    this.friendInfo,
  });

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      id: map['id'],
      childId: map['child_id'],
      friendId: map['friend_id'],
      isBestFriend: map['is_best_friend'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      friendInfo: map['friend'] != null
          ? ChildInfo.fromMap(map['friend'])
          : null,
    );
  }
}

class ChildInfo {
  final String id;
  final String nickname;
  final String? avatarUrl;

  ChildInfo({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  factory ChildInfo.fromMap(Map<String, dynamic> map) {
    return ChildInfo(
      id: map['id'],
      nickname: map['nickname'],
      avatarUrl: map['avatar_url'],
    );
  }
}