import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _defaultAndroidBaseUrl = 'http://10.0.2.2:8000';
  static const String _defaultIosBaseUrl = 'http://localhost:8000';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(minutes: 5);

  static String get baseUrl {
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
      return envBaseUrl;
    }

    // Platform-specific defaults
    if (kIsWeb) {
      // For web, use localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return _defaultAndroidBaseUrl;
    } else if (Platform.isIOS) {
      return _defaultIosBaseUrl;
    } else {
      // Fallback for other platforms
      return _defaultIosBaseUrl;
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
