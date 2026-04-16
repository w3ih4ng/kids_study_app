import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/friend_model.dart';

final supabase = Supabase.instance.client;

class FriendService {
  // ── Friends ───────────────────────────────────────
  static Future<List<FriendModel>> getFriends(String childId) async {
    final response = await supabase
        .from('friends')
        .select('*, friend:friend_id(id, nickname, avatar_url, child_code)')
        .eq('child_id', childId)
        .order('is_best_friend', ascending: false);
    return (response as List)
        .map((e) => FriendModel.fromMap(e))
        .toList();
  }

  static Future<bool> isFriend({
    required String childId,
    required String friendId,
  }) async {
    final response = await supabase
        .from('friends')
        .select()
        .eq('child_id', childId)
        .eq('friend_id', friendId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  static Future<void> removeFriend({
    required String childId,
    required String friendId,
  }) async {
    await supabase
        .from('friends')
        .delete()
        .eq('child_id', childId)
        .eq('friend_id', friendId);
    await supabase
        .from('friends')
        .delete()
        .eq('child_id', friendId)
        .eq('friend_id', childId);
  }

  static Future<void> toggleBestFriend({
    required String childId,
    required String friendId,
    required bool isBestFriend,
  }) async {
    await supabase
        .from('friends')
        .update({'is_best_friend': isBestFriend})
        .eq('child_id', childId)
        .eq('friend_id', friendId);
  }

  // ── Search ────────────────────────────────────────
  static Future<List<ChildInfo>> searchChildren({
    required String query,
    required String currentChildId,
  }) async {
    if (query.trim().isEmpty) return [];

    // Search by nickname OR child code
    final response = await supabase
        .from('children_public')
        .select('id, nickname, avatar_url, child_code')
        .or('nickname.ilike.%$query%,child_code.ilike.%$query%')
        .neq('id', currentChildId)
        .limit(10);

    return (response as List)
        .map((e) => ChildInfo.fromMap(e))
        .toList();
  }

  // ── Friend Requests ───────────────────────────────
  static Future<void> sendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    await supabase.from('friend_requests').upsert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'status': 'pending',
    }, onConflict: 'sender_id, receiver_id');
  }

  // Check if request already sent
  static Future<String?> getRequestStatus({
    required String senderId,
    required String receiverId,
  }) async {
    final response = await supabase
        .from('friend_requests')
        .select('status')
        .eq('sender_id', senderId)
        .eq('receiver_id', receiverId)
        .limit(1);
    final list = response as List;
    return list.isNotEmpty ? list.first['status'] as String : null;
  }

  // Get pending requests for a child
  static Future<List<FriendRequestModel>> getPendingRequests(
      String childId) async {
    final response = await supabase
        .from('friend_requests')
        .select('*, sender:sender_id(id, nickname, avatar_url, child_code)')
        .eq('receiver_id', childId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => FriendRequestModel.fromMap(e))
        .toList();
  }

  // Accept request
  static Future<void> acceptRequest({
    required String requestId,
    required String senderId,
    required String receiverId,
  }) async {
    // Update request status
    await supabase
        .from('friend_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);

    // Add mutual friendship
    await supabase.from('friends').upsert([
      {'child_id': senderId, 'friend_id': receiverId},
      {'child_id': receiverId, 'friend_id': senderId},
    ], onConflict: 'child_id, friend_id');
  }

  // Decline request
  static Future<void> declineRequest(String requestId) async {
    await supabase
        .from('friend_requests')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }
}