import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/leaderboard_model.dart';

final supabase = Supabase.instance.client;

class LeaderboardService {
  // Get top leaderboard
  static Future<List<LeaderboardModel>> getLeaderboard({
    int limit = 20,
  }) async {
    final response = await supabase
        .from('leaderboard')
        .select('*, children(id, nickname, avatar_url)')
        .order('score', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => LeaderboardModel.fromMap(e))
        .toList();
  }

  // Get rank of a specific child
  static Future<int> getChildRank(String childId) async {
    final response = await supabase
        .from('leaderboard')
        .select('child_id')
        .order('score', ascending: false);
    final list = response as List;
    final index =
    list.indexWhere((e) => e['child_id'] == childId);
    return index == -1 ? 0 : index + 1;
  }

  // Get stats for a specific child
  static Future<LeaderboardModel?> getChildStats(
      String childId) async {
    final response = await supabase
        .from('leaderboard')
        .select('*, children(id, nickname, avatar_url)')
        .eq('child_id', childId)
        .limit(1);
    final list = response as List;
    return list.isNotEmpty
        ? LeaderboardModel.fromMap(list.first)
        : null;
  }

  // Update leaderboard after quiz
  static Future<void> updateAfterQuiz({
    required String childId,
    required int coinsEarned,
    required int correctAnswers,
  }) async {
    await supabase.rpc('update_leaderboard', params: {
      'child_id_input': childId,
      'coins_input': coinsEarned,
      'correct_input': correctAnswers,
    });
  }
}