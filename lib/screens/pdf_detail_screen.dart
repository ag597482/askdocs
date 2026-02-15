import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/pdf_info.dart';
import '../widgets/chapter_chip.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'ask_screen.dart';
import 'quiz_screen.dart';

class PDFDetailScreen extends StatefulWidget {
  final PDFInfo pdf;

  const PDFDetailScreen({super.key, required this.pdf});

  @override
  State<PDFDetailScreen> createState() => _PDFDetailScreenState();
}

class _PDFDetailScreenState extends State<PDFDetailScreen> {
  final _apiService = ApiService();
  final _ttsService = TTSService();
  bool _isLoadingSummary = false;
  String? _summary;
  String? _summaryType;
  String? _summaryError;
  int? _selectedPageNumber;
  bool _isTtsPlaying = false;
  bool _isTtsPaused = false;

  @override
  void initState() {
    super.initState();
    _ttsService.setOnStateChanged(() {
      if (mounted) {
        setState(() {
          _isTtsPlaying = _ttsService.isPlaying;
          _isTtsPaused = _ttsService.isPaused;
        });
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.setOnStateChanged(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.pdf.name,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat), text: 'Ask'),
              Tab(icon: Icon(Icons.summarize), text: 'Summary'),
              Tab(icon: Icon(Icons.description), text: 'Page'),
              Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
            ],
            isScrollable: true,
          ),
        ),
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: theme.colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pdf.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uploaded by ${widget.pdf.uploadedBy}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.description,
                        label: '${widget.pdf.totalPages} pages',
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: dateFormat.format(widget.pdf.uploadDate),
                      ),
                    ],
                  ),
                  if (widget.pdf.chapters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Chapters:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.pdf.chapters.map((chapter) {
                        return ChapterChip(
                          chapterName: chapter,
                          onSummaryTap: () => _getChapterSummary(chapter),
                          onQuizTap: () => _navigateToQuiz(chapter: chapter),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  // Ask Tab
                  _buildAskTab(),
                  // Full Summary Tab
                  _buildFullSummaryTab(),
                  // Page Summary Tab
                  _buildPageSummaryTab(),
                  // Quiz Tab
                  _buildQuizTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask Questions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Get answers about this PDF using AI',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AskScreen(pdf: widget.pdf),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Start Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoadingSummary ? null : _getFullSummary,
            icon: _isLoadingSummary
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.summarize),
            label: Text(_isLoadingSummary
                ? 'Generating your summary...'
                : 'Generate Full Summary'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_summaryError != null) ...[
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
                      _summaryError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_summary != null && _summaryType == 'complete') ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Full Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildTTSControls(_summary!),
                      ],
                    ),
                    const Divider(),
                    MarkdownBody(data: _summary!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Page Number',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              // Make active and inactive track the same color (no progress fill)
              activeTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              // Make the thumb stand out as the position indicator
              thumbColor: Theme.of(context).colorScheme.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              // Show tick marks for each page
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
              activeTickMarkColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              inactiveTickMarkColor: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              trackHeight: 4,
            ),
            child: Slider(
              value: (_selectedPageNumber ?? 1).toDouble(),
              min: 1,
              max: widget.pdf.totalPages.toDouble(),
              divisions: widget.pdf.totalPages - 1,
              label: 'Page ${_selectedPageNumber ?? 1}',
              onChanged: (value) {
                setState(() {
                  _selectedPageNumber = value.toInt();
                });
              },
            ),
          ),
          Text(
            'Page ${_selectedPageNumber ?? 1} of ${widget.pdf.totalPages}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoadingSummary
                ? null
                : () => _getPageSummary(_selectedPageNumber ?? 1),
            icon: _isLoadingSummary
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.summarize),
            label: Text(_isLoadingSummary
                ? 'Generating page summary...'
                : 'Get Page Summary'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_summaryError != null) ...[
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
                      _summaryError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_summary != null && _summaryType == 'page') ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Page ${_selectedPageNumber ?? 1} Summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        _buildTTSControls(_summary!),
                      ],
                    ),
                    const Divider(),
                    MarkdownBody(data: _summary!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Generate Quiz',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Test your knowledge with AI-generated questions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToQuiz(),
              icon: const Icon(Icons.quiz),
              label: const Text('Start Quiz'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getFullSummary() async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _summary = null;
    });

    try {
      final response = await _apiService.getSummary(
        pdf: widget.pdf.name,
        type: 'complete',
      );
      setState(() {
        _summary = response.summary;
        _summaryType = 'complete';
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString().replaceAll('Exception: ', '');
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _getPageSummary(int pageNumber) async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _summary = null;
    });

    try {
      final response = await _apiService.getSummary(
        pdf: widget.pdf.name,
        type: 'page',
        pageNumber: pageNumber,
      );
      setState(() {
        _summary = response.summary;
        _summaryType = 'page';
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _summaryError = e.toString().replaceAll('Exception: ', '');
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _getChapterSummary(String chapter) async {
    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
      _summary = null;
    });

    try {
      final response = await _apiService.getSummary(
        pdf: widget.pdf.name,
        type: 'chapter',
        chapter: chapter,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('Chapter: $chapter')),
                _buildTTSControls(response.summary, isDialog: true),
              ],
            ),
            content: SingleChildScrollView(
              child: MarkdownBody(data: response.summary),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _ttsService.stop();
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  void _navigateToQuiz({String? chapter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          pdf: widget.pdf,
          initialChapter: chapter,
        ),
      ),
    );
  }

  Widget _buildTTSControls(String text, {bool isDialog = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isTtsPlaying && !_isTtsPaused)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () async {
              await _ttsService.pause();
              setState(() {
                _isTtsPaused = true;
              });
            },
            tooltip: 'Pause',
          )
        else if (_isTtsPaused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () async {
              await _ttsService.resume();
              setState(() {
                _isTtsPaused = false;
              });
            },
            tooltip: 'Resume',
          )
        else
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () async {
              await _ttsService.speak(text);
            },
            tooltip: 'Read aloud',
          ),
        if (_isTtsPlaying || _isTtsPaused)
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () async {
              await _ttsService.stop();
              setState(() {
                _isTtsPlaying = false;
                _isTtsPaused = false;
              });
            },
            tooltip: 'Stop',
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
