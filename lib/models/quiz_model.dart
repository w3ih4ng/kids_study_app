class QuizModel {
  final String id;
  final String title;
  final String subject;
  final String? lessonId;
  final int coinValue;
  final DateTime createdAt;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    required this.subject,
    this.lessonId,
    required this.coinValue,
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
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;

  QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'],
      quizId: map['quiz_id'],
      question: map['question'],
      optionA: map['option_a'],
      optionB: map['option_b'],
      optionC: map['option_c'],
      optionD: map['option_d'],
      correctAnswer: map['correct_answer'],
    );
  }

  String optionText(String key) {
    switch (key) {
      case 'a': return optionA;
      case 'b': return optionB;
      case 'c': return optionC;
      case 'd': return optionD;
      default: return '';
    }
  }
}