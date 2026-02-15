import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefsKey = 'base_url';
  static const String _defaultBaseUrl = 'https://rag1-askdocs.up.railway.app';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(minutes: 5);

  static String? _cachedBaseUrl;

  static String get baseUrl {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    // If not initialized, return default
    return _defaultBaseUrl;
  }

  static Future<void> initialize() async {
    // Try to load from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefsKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _cachedBaseUrl = savedUrl;
        return;
      }
    } catch (e) {
      // SharedPreferences not available, use defaults
    }

    // Check if BASE_URL is set via environment variable (if supported)
    String? envBaseUrl;
    try {
      if (!kIsWeb) {
        envBaseUrl = Platform.environment['BASE_URL'];
      }
    } catch (e) {
      // Platform.environment not supported in this context
    }
    
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      _cachedBaseUrl = envBaseUrl;
      return;
    }

    // Use default
    _cachedBaseUrl = _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    _cachedBaseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, url);
    } catch (e) {
      // SharedPreferences not available
    }
  }

  static Duration get defaultTimeout => _defaultTimeout;
  static Duration get uploadTimeout => _uploadTimeout;

  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String uploadEndpoint = '/upload';
  static const String pdfsEndpoint = '/pdfs';
  static const String askEndpoint = '/ask';
  static const String summaryEndpoint = '/summary';
  static const String quizEndpoint = '/quiz';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
