import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/quiz_question.dart';

class QuizQuestionCard extends StatefulWidget {
  final QuizQuestion question;
  final int questionIndex;
  final String? userAnswer;
  final bool isSubmitted;
  final bool? isCorrect;
  final Function(String) onAnswerChanged;

  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.questionIndex,
    this.userAnswer,
    required this.isSubmitted,
    this.isCorrect,
    required this.onAnswerChanged,
  });

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  late String? _selectedAnswer;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.userAnswer;
    _textController = TextEditingController(text: widget.userAnswer ?? '');
  }

  @override
  void didUpdateWidget(QuizQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userAnswer != oldWidget.userAnswer) {
      _selectedAnswer = widget.userAnswer;
      // Only update controller if the value actually changed externally
      if (_textController.text != (widget.userAnswer ?? '')) {
        _textController.text = widget.userAnswer ?? '';
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = widget.isCorrect;
    final showResult = widget.isSubmitted && isCorrect != null;

    Color? borderColor;
    if (showResult) {
      borderColor = isCorrect ? Colors.green : Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Question ${widget.questionIndex + 1}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (showResult)
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: widget.question.question,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnswerInput(theme, showResult),
            if (showResult) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Answer:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.question.answer,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (widget.question.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Explanation:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MarkdownBody(
                        data: widget.question.explanation,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(ThemeData theme, bool showResult) {
    switch (widget.question.type) {
      case 'mcq':
        return _buildMCQOptions(theme, showResult);
      case 'true_false':
        return _buildTrueFalseOptions(theme, showResult);
      case 'short_answer':
        return _buildShortAnswerInput(theme, showResult);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMCQOptions(ThemeData theme, bool showResult) {
    if (widget.question.options == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: widget.question.options!.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrectOption = option == widget.question.answer;

        Color? optionColor;
        if (showResult) {
          if (isCorrectOption) {
            optionColor = Colors.green.withOpacity(0.2);
          } else if (isSelected && !isCorrectOption) {
            optionColor = Colors.red.withOpacity(0.2);
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: optionColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            value: option,
            groupValue: _selectedAnswer,
            onChanged: showResult ? null : (value) {
              setState(() {
                _selectedAnswer = value;
              });
              widget.onAnswerChanged(value ?? '');
            },
            title: Text(option),
            dense: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(ThemeData theme, bool showResult) {
    final isTrueSelected = _selectedAnswer?.toLowerCase() == 'true';
    final isFalseSelected = _selectedAnswer?.toLowerCase() == 'false';
    final correctAnswer = widget.question.answer.toLowerCase() == 'true';

    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            theme: theme,
            label: 'True',
            isSelected: isTrueSelected,
            isCorrect: showResult && correctAnswer,
            isWrong: showResult && !correctAnswer && isTrueSelected,
            onTap: showResult
                ? null
                : () {
                    setState(() {
                      _selectedAnswer = 'True';
                    });
                    widget.onAnswerChanged('True');
                  },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildToggleButton(
            theme: theme,
            label: 'False',
            isSelected: isFalseSelected,
            isCorrect: showResult && !correctAnswer,
            isWrong: showResult && correctAnswer && isFalseSelected,
            onTap: showResult
                ? null
                : () {
                    setState(() {
                      _selectedAnswer = 'False';
                    });
                    widget.onAnswerChanged('False');
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required VoidCallback? onTap,
  }) {
    Color? backgroundColor;
    if (isCorrect) {
      backgroundColor = Colors.green.withOpacity(0.2);
    } else if (isWrong) {
      backgroundColor = Colors.red.withOpacity(0.2);
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortAnswerInput(ThemeData theme, bool showResult) {
    return TextField(
      enabled: !showResult,
      controller: _textController,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        _selectedAnswer = value;
        widget.onAnswerChanged(value);
      },
      maxLines: 3,
    );
  }
}
