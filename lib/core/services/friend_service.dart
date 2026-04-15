import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/friend_model.dart';

final supabase = Supabase.instance.client;

class FriendService {
  // Get all friends for a child
  static Future<List<FriendModel>> getFriends(String childId) async {
    final response = await supabase
        .from('friends')
        .select('*, friend:friend_id(id, nickname, avatar_url)')
        .eq('child_id', childId)
        .order('is_best_friend', ascending: false);
    return (response as List)
        .map((e) => FriendModel.fromMap(e))
        .toList();
  }

  // Search children by nickname
  static Future<List<ChildInfo>> searchChildren({
    required String query,
    required String currentChildId,
  }) async {
    final response = await supabase
        .from('children')
        .select('id, nickname, avatar_url')
        .ilike('nickname', '%$query%')
        .neq('id', currentChildId)
        .limit(10);
    return (response as List)
        .map((e) => ChildInfo.fromMap(e))
        .toList();
  }

  // Add friend
  static Future<void> addFriend({
    required String childId,
    required String friendId,
  }) async {
    // Add both ways so friendship is mutual
    await supabase.from('friends').upsert([
      {'child_id': childId, 'friend_id': friendId},
      {'child_id': friendId, 'friend_id': childId},
    ], onConflict: 'child_id, friend_id');
  }

  // Check if already friends
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

  // Toggle best friend
  static Future<void> toggleBestFriend({
    required String friendId,
    required String childId,
    required bool isBestFriend,
  }) async {
    await supabase
        .from('friends')
        .update({'is_best_friend': isBestFriend})
        .eq('child_id', childId)
        .eq('friend_id', friendId);
  }

  // Remove friend
  static Future<void> removeFriend({
    required String childId,
    required String friendId,
  }) async {
    // Remove both directions
    await supabase
        .from('friends')
        .delete()
        .eq('child_id', childId)
        .eq('friend_id', friendId);
    await supabase
        .from('friends')
        .delete()
        .eq('child_id', friendId)
        .eq('child_id', childId);
  }
}