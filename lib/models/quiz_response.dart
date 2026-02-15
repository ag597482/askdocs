import '../models/quiz_question.dart';

class QuizResponse {
  final String pdf;
  final String type;
  final List<QuizQuestion> questions;

  QuizResponse({
    required this.pdf,
    required this.type,
    required this.questions,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      pdf: json['pdf'] as String,
      type: json['type'] as String,
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pdf': pdf,
      'type': type,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}
