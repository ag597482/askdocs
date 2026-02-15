import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../providers/pdf_provider.dart';
import '../providers/quiz_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  String? _selectedPreset;
  bool _isSaving = false;

  static const String _prefsKey = 'base_url';
  static const String _defaultBaseUrl = 'https://rag1-askdocs.up.railway.app';
  static const List<String> _presetUrls = [
    'http://localhost:8000',
    'https://rag1-askdocs.up.railway.app',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefsKey) ?? _defaultBaseUrl;
    
    setState(() {
      _urlController.text = savedUrl;
      // Check if it matches a preset
      if (_presetUrls.contains(savedUrl)) {
        _selectedPreset = savedUrl;
      } else {
        _selectedPreset = 'custom';
      }
    });
  }

  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final url = _urlController.text.trim();
      
      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('URL must start with http:// or https://');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, url);

      // Update ApiConfig
      await ApiConfig.setBaseUrl(url);
      
      // Refresh providers to use new base URL
      if (mounted) {
        context.read<PDFProvider>().refreshApiService();
        context.read<QuizProvider>().refreshApiService();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base URL saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving URL: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _onPresetSelected(String? value) {
    if (value != null && value != 'custom') {
      setState(() {
        _selectedPreset = value;
        _urlController.text = value;
      });
    } else {
      setState(() {
        _selectedPreset = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                        'Base URL Configuration',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure the backend API base URL for all API calls.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Preset',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPreset,
                decoration: const InputDecoration(
                  labelText: 'Choose a preset URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list),
                ),
                items: [
                  ..._presetUrls.map((url) => DropdownMenuItem(
                        value: url,
                        child: Text(url),
                      )),
                  const DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom URL'),
                  ),
                ],
                onChanged: _onPresetSelected,
              ),
              const SizedBox(height: 24),
              Text(
                'Base URL',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a base URL';
                  }
                  final url = value.trim();
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
                enabled: !_isSaving,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current URL: ${ApiConfig.baseUrl}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveUrl,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Base URL'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _urlController.text = _defaultBaseUrl;
                          _selectedPreset = _defaultBaseUrl;
                        });
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Default'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
