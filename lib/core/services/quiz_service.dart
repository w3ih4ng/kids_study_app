import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/quiz_model.dart';
import 'leaderboard_service.dart';

final supabase = Supabase.instance.client;

class QuizService {
  static Future<List<QuizModel>> getQuizzes({String? subject}) async {
    final response = subject != null
        ? await supabase
              .from('quizzes')
              .select('*, quiz_questions(*)')
              .eq('subject', subject)
              .order('created_at', ascending: false)
        : await supabase
              .from('quizzes')
              .select('*, quiz_questions(*)')
              .order('created_at', ascending: false);

    return (response as List).map((e) => QuizModel.fromMap(e)).toList();
  }

  static Future<void> createQuiz({
    required String title,
    required String subject,
    String? lessonId,
    int coinValue = 100,
    String ageLevel = '6+',
    String? thumbnailUrl,
  }) async {
    await supabase.from('quizzes').insert({
      'title': title,
      'subject': subject,
      'lesson_id': lessonId,
      'coin_value': coinValue,
      'age_level': ageLevel,
      'thumbnail_url': thumbnailUrl,
    });
  }

  static Future<void> updateQuiz(String id, Map<String, dynamic> data) async {
    await supabase.from('quizzes').update(data).eq('id', id);
  }

  static Future<void> addQuestion({
    required String quizId,
    required String question,
    String? questionImageUrl,
    required String optionA,
    String? optionAImageUrl,
    required String optionB,
    String? optionBImageUrl,
    required String optionC,
    String? optionCImageUrl,
    required String optionD,
    String? optionDImageUrl,
    required String correctAnswer,
    bool isMultipleAnswer = false,
    List<String> correctAnswers = const [],
  }) async {
    await supabase.from('quiz_questions').insert({
      'quiz_id': quizId,
      'question': question,
      'question_image_url': questionImageUrl,
      'option_a': optionA,
      'option_a_image_url': optionAImageUrl,
      'option_b': optionB,
      'option_b_image_url': optionBImageUrl,
      'option_c': optionC,
      'option_c_image_url': optionCImageUrl,
      'option_d': optionD,
      'option_d_image_url': optionDImageUrl,
      'correct_answer': correctAnswer,
      'is_multiple_answer': isMultipleAnswer,
      'correct_answers': correctAnswers.isEmpty ? null : correctAnswers,
    });
  }

  static Future<void> updateQuestion(
    String id,
    Map<String, dynamic> data,
  ) async {
    await supabase.from('quiz_questions').update(data).eq('id', id);
  }

  static Future<void> deleteQuiz(String id) async {
    await supabase.from('quizzes').delete().eq('id', id);
  }

  static Future<void> deleteQuestion(String id) async {
    await supabase.from('quiz_questions').delete().eq('id', id);
  }

  // Check if child has already attempted this quiz
  static Future<bool> hasAttempted({
    required String childId,
    required String quizId,
  }) async {
    final response = await supabase
        .from('quiz_results')
        .select()
        .eq('child_id', childId)
        .eq('quiz_id', quizId)
        .limit(1);
    return (response as List).isNotEmpty;
  }

  // Get first attempt result for a quiz
  static Future<Map<String, dynamic>?> getFirstAttempt({
    required String childId,
    required String quizId,
  }) async {
    final response = await supabase
        .from('quiz_results')
        .select()
        .eq('child_id', childId)
        .eq('quiz_id', quizId)
        .eq('is_first_attempt', true)
        .limit(1);
    final list = response as List;
    return list.isNotEmpty ? list.first : null;
  }

  // Submit quiz result
  static Future<({int coinsEarned, bool isFirstAttempt})> submitResult({
    required String childId,
    required String quizId,
    required int score,
    required int total,
    required int quizCoinValue,
  }) async {
    final firstAttempt = !await hasAttempted(childId: childId, quizId: quizId);

    // Only award coins on first attempt
    final coinsEarned = firstAttempt
        ? ((score / total) * quizCoinValue).round()
        : 0;

    await supabase.from('quiz_results').insert({
      'child_id': childId,
      'quiz_id': quizId,
      'score': score,
      'total': total,
      'coins_earned': coinsEarned,
      'is_first_attempt': firstAttempt,
    });

    if (firstAttempt && coinsEarned > 0) {
      await supabase.rpc(
        'add_coins',
        params: {'child_id_input': childId, 'coins_input': coinsEarned},
      );
      // Log transaction
      await supabase.from('coin_transactions').insert({
        'child_id': childId,
        'amount': coinsEarned,
        'type': 'quiz',
        'description': 'Quiz completed',
      });
    }

    // Update leaderboard
    if (firstAttempt) {
      try {
        await LeaderboardService.updateAfterQuiz(
          childId: childId,
          coinsEarned: coinsEarned,
          correctAnswers: score,
        );
      } catch (e) {
        debugPrint('Leaderboard update error: $e');
      }
    }

    return (coinsEarned: coinsEarned, isFirstAttempt: firstAttempt);
  }

  // Get all results for a child (for reports)
  static Future<List<Map<String, dynamic>>> getResultsForChild(
    String childId,
  ) async {
    final response = await supabase
        .from('quiz_results')
        .select('*, quizzes(title, subject)')
        .eq('child_id', childId)
        .order('completed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
