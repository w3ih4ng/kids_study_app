class QuizModel {
  final String id;
  final String title;
  final String subject;
  final String? lessonId;
  final int coinValue;
  final String ageLevel;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    required this.subject,
    this.lessonId,
    required this.coinValue,
    this.ageLevel = '6+',
    this.thumbnailUrl,
    required this.createdAt,
    this.questions = const [],
  });

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'],
      title: map['title'],
      subject: map['subject'],
      lessonId: map['lesson_id'],
      coinValue: map['coin_value'] ?? 100,
      ageLevel: map['age_level'] ?? '6+',
      thumbnailUrl: map['thumbnail_url'],
      createdAt: DateTime.parse(map['created_at']),
      questions: map['quiz_questions'] != null
          ? (map['quiz_questions'] as List)
                .map((q) => QuizQuestionModel.fromMap(q))
                .toList()
          : [],
    );
  }
}

class QuizQuestionModel {
  final String id;
  final String quizId;
  final String question;
  final String? questionImageUrl;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? optionAImageUrl;
  final String? optionBImageUrl;
  final String? optionCImageUrl;
  final String? optionDImageUrl;
  final String correctAnswer; // single answer 'a'|'b'|'c'|'d'
  final bool isMultipleAnswer; // new
  final List<String> correctAnswers; // new ['a','c'] for multiple

  QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.question,
    this.questionImageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.optionAImageUrl,
    this.optionBImageUrl,
    this.optionCImageUrl,
    this.optionDImageUrl,
    required this.correctAnswer,
    this.isMultipleAnswer = false,
    this.correctAnswers = const [],
  });

  // All correct answers as a list — works for both single and multiple
  List<String> get allCorrectAnswers =>
      isMultipleAnswer && correctAnswers.isNotEmpty
      ? correctAnswers
      : [correctAnswer];

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'],
      quizId: map['quiz_id'],
      question: map['question'] ?? '',
      questionImageUrl: map['question_image_url'],
      optionA: map['option_a'] ?? '',
      optionB: map['option_b'] ?? '',
      optionC: map['option_c'] ?? '',
      optionD: map['option_d'] ?? '',
      optionAImageUrl: map['option_a_image_url'],
      optionBImageUrl: map['option_b_image_url'],
      optionCImageUrl: map['option_c_image_url'],
      optionDImageUrl: map['option_d_image_url'],
      correctAnswer: map['correct_answer'] ?? 'a',
      isMultipleAnswer: map['is_multiple_answer'] ?? false,
      correctAnswers: map['correct_answers'] != null
          ? List<String>.from(map['correct_answers'])
          : [],
    );
  }

  // Get text for a given option key
  String optionText(String key) {
    switch (key) {
      case 'a':
        return optionA;
      case 'b':
        return optionB;
      case 'c':
        return optionC;
      case 'd':
        return optionD;
      default:
        return '';
    }
  }

  // Get image url for a given option key
  String? optionImageUrl(String key) {
    switch (key) {
      case 'a':
        return optionAImageUrl;
      case 'b':
        return optionBImageUrl;
      case 'c':
        return optionCImageUrl;
      case 'd':
        return optionDImageUrl;
      default:
        return null;
    }
  }
}
