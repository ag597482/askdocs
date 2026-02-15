import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_info.dart';
import '../providers/quiz_provider.dart';
import '../widgets/quiz_question_card.dart';

class QuizScreen extends StatefulWidget {
  final PDFInfo pdf;
  final String? initialChapter;

  const QuizScreen({
    super.key,
    required this.pdf,
    this.initialChapter,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _quizType = 'complete'; // 'complete' or 'chapter'
  String? _selectedChapter;
  int _numQuestions = 10;

  @override
  void initState() {
    super.initState();
    if (widget.initialChapter != null) {
      _quizType = 'chapter';
      _selectedChapter = widget.initialChapter;
    }
  }

  Future<void> _generateQuiz() async {
    final provider = context.read<QuizProvider>();
    final success = await provider.generateQuiz(
      pdf: widget.pdf.name,
      type: _quizType,
      chapter: _selectedChapter,
      numQuestions: _numQuestions,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to generate quiz'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pdf.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Quiz',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isGenerating) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Preparing quiz questions...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          if (provider.currentQuiz == null) {
            return _buildQuizSetup(provider);
          }

          if (provider.isSubmitted) {
            return _buildResults(provider);
          }

          return _buildQuiz(provider);
        },
      ),
    );
  }

  Widget _buildQuizSetup(QuizProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz Scope',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('Complete Book'),
                    value: 'complete',
                    groupValue: _quizType,
                    onChanged: (value) {
                      setState(() {
                        _quizType = value!;
                        _selectedChapter = null;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Specific Chapter'),
                    value: 'chapter',
                    groupValue: _quizType,
                    onChanged: (value) {
                      setState(() {
                        _quizType = value!;
                        if (widget.pdf.chapters.isNotEmpty &&
                            _selectedChapter == null) {
                          _selectedChapter = widget.pdf.chapters.first;
                        }
                      });
                    },
                  ),
                  if (_quizType == 'chapter' && widget.pdf.chapters.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedChapter,
                      decoration: const InputDecoration(
                        labelText: 'Select Chapter',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.pdf.chapters.map((chapter) {
                        return DropdownMenuItem(
                          value: chapter,
                          child: Text(
                            chapter,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedChapter = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number of Questions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _numQuestions.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 15,
                    label: '$_numQuestions questions',
                    onChanged: (value) {
                      setState(() {
                        _numQuestions = value.toInt();
                      });
                    },
                  ),
                  Text(
                    '$_numQuestions questions',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.isGenerating ? null : _generateQuiz,
            icon: const Icon(Icons.quiz),
            label: const Text('Generate Quiz'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuiz(QuizProvider provider) {
    final quiz = provider.currentQuiz!;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              return QuizQuestionCard(
                question: question,
                questionIndex: index,
                userAnswer: provider.userAnswers[index],
                isSubmitted: false,
                onAnswerChanged: (answer) {
                  provider.setAnswer(index, answer);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: provider.isSubmitting
                  ? null
                  : () => provider.submitQuiz(),
              icon: provider.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(provider.isSubmitting ? 'Submitting...' : 'Submit Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(QuizProvider provider) {
    final quiz = provider.currentQuiz!;
    final score = provider.score;
    final total = provider.totalQuestions;
    final percentage = (score / total * 100).round();

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            children: [
              Text(
                'Quiz Results',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '$score / $total',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage% Correct',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
        // Questions with Results
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: quiz.questions.length,
            itemBuilder: (context, index) {
              final question = quiz.questions[index];
              final isCorrect = provider.answerResults?[index] ?? false;
              return QuizQuestionCard(
                question: question,
                questionIndex: index,
                userAnswer: provider.userAnswers[index],
                isSubmitted: true,
                isCorrect: isCorrect,
                onAnswerChanged: (_) {},
              );
            },
          ),
        ),
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.resetQuiz();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Quiz'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      provider.resetQuiz();
                      _generateQuiz();
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('Retake'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
