import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/friend_model.dart';
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

  // Get leaderboard filtered to friends only
  static Future<List<LeaderboardModel>> getFriendsLeaderboard({
    required String childId,
  }) async {
    // Get friend ids first
    final friendsResponse = await supabase
        .from('friends')
        .select('friend_id')
        .eq('child_id', childId);

    final friendIds = (friendsResponse as List)
        .map((e) => e['friend_id'] as String)
        .toList();

    // Include self
    friendIds.add(childId);

    final response = await supabase
        .from('leaderboard')
        .select('*, children(id, nickname, avatar_url)')
        .inFilter('child_id', friendIds)
        .order('score', ascending: false);

    return (response as List)
        .map((e) => LeaderboardModel.fromMap(e))
        .toList();
  }

  static Future<List<LeaderboardModel>> getLeaderboardBySubject({
    required String subject,
  }) async {
    // Get quiz results grouped by child for a specific subject
    final response = await supabase
        .from('quiz_results')
        .select('child_id, score, total, coins_earned, quizzes(subject)')
        .eq('quizzes.subject', subject)
        .eq('is_first_attempt', true);

    final list = response as List;

    // Aggregate per child
    final Map<String, Map<String, int>> childStats = {};
    for (final r in list) {
      if (r['quizzes'] == null) continue;
      final childId = r['child_id'] as String;
      childStats.putIfAbsent(
          childId, () => {'correct': 0, 'coins': 0, 'score': 0});
      childStats[childId]!['correct'] =
          childStats[childId]!['correct']! + (r['score'] as int? ?? 0);
      childStats[childId]!['coins'] =
          childStats[childId]!['coins']! +
              (r['coins_earned'] as int? ?? 0);
    }

    if (childStats.isEmpty) return [];

    // Calculate scores
    childStats.forEach((childId, stats) {
      stats['score'] = stats['coins']! + (stats['correct']! * 10);
    });

    // Get child info
    final childIds = childStats.keys.toList();
    final childResponse = await supabase
        .from('children')
        .select('id, nickname, avatar_url')
        .inFilter('id', childIds);

    final childMap = {
      for (final c in childResponse as List)
        c['id'] as String: c
    };

    // Build leaderboard models
    final result = childStats.entries.map((e) {
      return LeaderboardModel(
        id: e.key,
        childId: e.key,
        totalCoins: e.value['coins']!,
        totalCorrect: e.value['correct']!,
        score: e.value['score']!,
        updatedAt: DateTime.now(),
        childInfo: childMap[e.key] != null
            ? ChildInfo.fromMap(childMap[e.key]!)
            : null,
      );
    }).toList();

    // Sort by score
    result.sort((a, b) => b.score.compareTo(a.score));
    return result;
  }
}