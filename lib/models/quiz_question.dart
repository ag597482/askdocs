class QuizQuestion {
  final String type; // "mcq", "true_false", or "short_answer"
  final String question;
  final List<String>? options; // Only for MCQ
  final String answer;
  final String explanation;

  QuizQuestion({
    required this.type,
    required this.question,
    this.options,
    required this.answer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      type: json['type'] as String,
      question: json['question'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      answer: json['answer'] as String,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'question': question,
      if (options != null) 'options': options,
      'answer': answer,
      'explanation': explanation,
    };
  }
}
