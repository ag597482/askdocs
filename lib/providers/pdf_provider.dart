import 'package:flutter/foundation.dart';
import '../models/pdf_info.dart';
import '../services/api_service.dart';

class PDFProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PDFInfo> _pdfs = [];
  bool _isLoading = false;
  String? _error;

  List<PDFInfo> get pdfs => _pdfs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPDFs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pdfs = await _apiService.getPDFsList();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _pdfs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPDFs() async {
    await fetchPDFs();
  }

  Future<bool> deletePDF(String name) async {
    try {
      await _apiService.deletePDF(name);
      await fetchPDFs(); // Refresh the list
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
