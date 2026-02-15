import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

// Conditional import for File - use stub on web
import 'dart:io' if (dart.library.html) '../services/file_stub.dart' as io;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _apiService = ApiService();

  // Only used on mobile platforms - using dynamic to avoid web compilation issues
  dynamic _selectedFile;
  PlatformFile? _selectedPlatformFile; // For web
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.size > 0) {
        setState(() {
          if (kIsWeb) {
            // For web, use PlatformFile with bytes
            _selectedPlatformFile = result.files.single;
            _selectedFile = null;
          } else {
            // For mobile, use File with path
            final path = result.files.single.path;
            if (path != null && !kIsWeb) {
              // Only create File on non-web platforms
              _selectedFile = io.File(path);
              _selectedPlatformFile = null;
            }
          }
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadPDF() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null && _selectedPlatformFile == null) {
      setState(() {
        _error = 'Please select a PDF file';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _error = null;
    });

    try {
      final result = kIsWeb
          ? await _apiService.uploadPDFWeb(
              fileBytes: _selectedPlatformFile!.bytes!,
              fileName: _selectedPlatformFile!.name,
              name: _nameController.text.trim(),
              username: _usernameController.text.trim(),
              onSendProgress: (sent, total) {
                setState(() {
                  _uploadProgress = sent / total;
                });
              },
            )
          : await _apiService.uploadPDF(
              file: _selectedFile!,
              name: _nameController.text.trim(),
              username: _usernameController.text.trim(),
              onSendProgress: (sent, total) {
                setState(() {
                  _uploadProgress = sent / total;
                });
              },
            );

      if (mounted) {
        _showSuccessDialog(result);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Upload failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final chapters = result['chapters_found'] as List<dynamic>? ?? [];
    final pages = result['pages'] as int? ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Upload Successful!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PDF: ${result['name']}'),
              const SizedBox(height: 8),
              Text('Pages extracted: $pages'),
              const SizedBox(height: 8),
              Text('Chapters found: ${chapters.length}'),
              if (chapters.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Chapters:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...chapters.take(5).map((ch) => Text('• $ch')),
                if (chapters.length > 5)
                  Text('... and ${chapters.length - 5} more'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload PDF'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // File Picker Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select PDF File',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose PDF File'),
                      ),
                      if (_selectedFile != null || _selectedPlatformFile != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  kIsWeb
                                      ? _selectedPlatformFile!.name
                                      : _selectedFile!.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _isUploading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedFile = null;
                                          _selectedPlatformFile = null;
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'PDF Name *',
                  hintText: 'Enter a unique name for this PDF',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                enabled: !_isUploading,
              ),
              const SizedBox(height: 16),
              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
                enabled: !_isUploading,
              ),
              const SizedBox(height: 24),
              // Upload Progress
              if (_isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              // Upload Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPDF,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
