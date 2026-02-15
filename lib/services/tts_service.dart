import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isPaused = false;
  VoidCallback? _onStateChanged;

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;

  void setOnStateChanged(VoidCallback? callback) {
    _onStateChanged = callback;
  }

  void _notifyStateChanged() {
    _onStateChanged?.call();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(1.0); // Normal speed (1.0 is standard)
    await _flutterTts.setPitch(1.0); // Normal pitch
    await _flutterTts.setVolume(1.0); // Full volume
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _isPaused = false;
      _notifyStateChanged();
    });
    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      _isPaused = false;
      _notifyStateChanged();
    });

    _isInitialized = true;
  }


  Future<void> speak(String text) async {
    try {
      await initialize();

      if (_isPlaying && !_isPaused) {
        // If already playing, stop and start new
        await stop();
      }

      if (text.trim().isEmpty) {
        return;
      }

      // Very minimal processing - just remove code blocks and clean basic markdown
      String plainText = text.trim();
      
      // Remove code blocks (multiline)
      plainText = plainText.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
      
      // Remove inline code backticks
      plainText = plainText.replaceAll('`', '');
      
      // Remove markdown links: [text](url) -> text
      plainText = plainText.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
      
      // Remove images
      plainText = plainText.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), '');
      
      // Remove header markers
      plainText = plainText.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
      
      // Remove bold markers (keep text)
      plainText = plainText.replaceAll('**', '');
      plainText = plainText.replaceAll('__', '');
      
      // Clean up spaces
      plainText = plainText.replaceAll(RegExp(r' {2,}'), ' ').trim();
      
      // Use original if processing removed too much
      if (plainText.isEmpty || (plainText.length < 10 && text.length > 50)) {
        plainText = text.trim();
      }

      if (plainText.isEmpty) {
        return;
      }

      _isPlaying = true;
      _isPaused = false;
      _notifyStateChanged();
      
      final result = await _flutterTts.speak(plainText);
      // Result: 1 = success, 0 = error
      if (result == 0) {
        // Error occurred, reset state
        _isPlaying = false;
        _isPaused = false;
        _notifyStateChanged();
      }
    } catch (e) {
      // Handle any errors
      _isPlaying = false;
      _isPaused = false;
      _notifyStateChanged();
      rethrow;
    }
  }

  Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      await _flutterTts.pause();
      _isPaused = true;
      _notifyStateChanged();
    }
  }

  Future<void> resume() async {
    if (_isPaused) {
      // Note: flutter_tts doesn't have a direct resume method
      // Pause/resume functionality is limited on some platforms
      // For now, we'll just mark as resumed - user can restart if needed
      _isPaused = false;
      _notifyStateChanged();
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _isPaused = false;
    _notifyStateChanged();
  }

  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  Future<void> dispose() async {
    await stop();
  }
}
