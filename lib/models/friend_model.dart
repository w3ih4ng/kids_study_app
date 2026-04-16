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
  final String? childCode;

  ChildInfo({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.childCode,
  });

  factory ChildInfo.fromMap(Map<String, dynamic> map) {
    return ChildInfo(
      id: map['id'],
      nickname: map['nickname'],
      avatarUrl: map['avatar_url'],
      childCode: map['child_code'],
    );
  }
}

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  final ChildInfo? senderInfo;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.senderInfo,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      senderInfo: map['sender'] != null
          ? ChildInfo.fromMap(map['sender'])
          : null,
    );
  }
}