import 'package:flutter/foundation.dart';
import '../models/quiz_response.dart';
import '../services/api_service.dart';

class QuizProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  QuizResponse? _currentQuiz;
  Map<int, String> _userAnswers = {}; // question index -> user answer
  bool _isGenerating = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  Map<int, bool>? _answerResults; // question index -> is correct
  String? _error;

  QuizResponse? get currentQuiz => _currentQuiz;
  Map<int, String> get userAnswers => _userAnswers;
  bool get isGenerating => _isGenerating;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmitted => _isSubmitted;
  Map<int, bool>? get answerResults => _answerResults;
  String? get error => _error;

  int get score {
    if (_answerResults == null) return 0;
    return _answerResults!.values.where((isCorrect) => isCorrect).length;
  }

  int get totalQuestions => _currentQuiz?.questions.length ?? 0;

  Future<bool> generateQuiz({
    required String pdf,
    required String type,
    String? chapter,
    int? numQuestions,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _currentQuiz = await _apiService.generateQuiz(
        pdf: pdf,
        type: type,
        chapter: chapter,
        numQuestions: numQuestions,
      );
      _userAnswers = {};
      _isSubmitted = false;
      _answerResults = null;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void setAnswer(int questionIndex, String answer) {
    _userAnswers[questionIndex] = answer;
    notifyListeners();
  }

  Future<void> submitQuiz() async {
    if (_currentQuiz == null) return;

    _isSubmitting = true;
    notifyListeners();

    // Simulate processing delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    _answerResults = {};
    for (int i = 0; i < _currentQuiz!.questions.length; i++) {
      final question = _currentQuiz!.questions[i];
      final userAnswer = _userAnswers[i] ?? '';
      final correctAnswer = question.answer.toLowerCase().trim();
      final userAnswerNormalized = userAnswer.toLowerCase().trim();

      // For short answer, do a more lenient comparison
      if (question.type == 'short_answer') {
        _answerResults![i] = userAnswerNormalized == correctAnswer ||
            correctAnswer.contains(userAnswerNormalized) ||
            userAnswerNormalized.contains(correctAnswer);
      } else {
        _answerResults![i] = userAnswerNormalized == correctAnswer;
      }
    }

    _isSubmitted = true;
    _isSubmitting = false;
    notifyListeners();
  }

  void resetQuiz() {
    _currentQuiz = null;
    _userAnswers = {};
    _isSubmitted = false;
    _answerResults = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
