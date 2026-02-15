class AskResponse {
  final String answer;
  final bool contextFound;
  final String pdf;

  AskResponse({
    required this.answer,
    required this.contextFound,
    required this.pdf,
  });

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    return AskResponse(
      answer: json['answer'] as String,
      contextFound: json['context_found'] as bool,
      pdf: json['pdf'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answer': answer,
      'context_found': contextFound,
      'pdf': pdf,
    };
  }
}
