import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../widgets/pdf_card.dart';
import '../widgets/loading_shimmer.dart';
import 'upload_screen.dart';
import 'pdf_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PDFProvider>().fetchPDFs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ).then((_) {
              // Refresh PDF list after settings change
              context.read<PDFProvider>().fetchPDFs();
            });
          },
          child: const Text('Book Summarizer'),
        ),
        elevation: 0,
      ),
      body: Consumer<PDFProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pdfs.isEmpty) {
            return ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const PDFCardShimmer(),
            );
          }

          if (provider.error != null && provider.pdfs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading PDFs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchPDFs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.pdfs.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshPDFs(),
            child: ListView.builder(
              itemCount: provider.pdfs.length,
              itemBuilder: (context, index) {
                final pdf = provider.pdfs[index];
                return Dismissible(
                  key: Key(pdf.name),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await _confirmDelete(context, pdf.name, provider);
                  },
                  onDismissed: (direction) {
                    provider.deletePDF(pdf.name);
                  },
                  child: PDFCard(
                    pdf: pdf,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFDetailScreen(pdf: pdf),
                        ),
                      );
                    },
                    onDelete: () => _confirmDelete(context, pdf.name, provider),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadScreen(),
            ),
          ).then((_) {
            // Refresh PDF list after upload
            context.read<PDFProvider>().fetchPDFs();
          });
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 120,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload your first book',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by uploading a PDF to get summaries,\nask questions, and take quizzes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadScreen(),
                ),
              ).then((_) {
                context.read<PDFProvider>().fetchPDFs();
              });
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload PDF'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    String pdfName,
    PDFProvider provider,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "$pdfName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
