import 'package:flutter/material.dart';

class ChapterChip extends StatelessWidget {
  final String chapterName;
  final VoidCallback? onTap;
  final VoidCallback? onSummaryTap;
  final VoidCallback? onQuizTap;

  const ChapterChip({
    super.key,
    required this.chapterName,
    this.onTap,
    this.onSummaryTap,
    this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showChapterOptions(context),
      child: Chip(
        label: Text(
          chapterName,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        avatar: const Icon(Icons.bookmark, size: 18),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        onDeleted: onTap != null
            ? null
            : () => _showChapterOptions(context),
        deleteIcon: const Icon(Icons.more_horiz, size: 18),
      ),
    );
  }

  void _showChapterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Get Summary'),
              onTap: () {
                Navigator.pop(context);
                onSummaryTap?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Generate Quiz'),
              onTap: () {
                Navigator.pop(context);
                onQuizTap?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
