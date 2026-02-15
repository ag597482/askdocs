// Conditional import - File only exists on non-web platforms
import 'dart:io' if (dart.library.html) 'package:askdocs/services/file_stub.dart' as io;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/pdf_info.dart';
import '../models/ask_response.dart';
import '../models/summary_response.dart';
import '../models/quiz_response.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.defaultTimeout,
        receiveTimeout: ApiConfig.defaultTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors for error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<void> updateBaseUrl(String newBaseUrl) async {
    await ApiConfig.setBaseUrl(newBaseUrl);
    _dio.options.baseUrl = newBaseUrl;
  }

  String _handleError(DioException error) {
    // Check for CORS errors
    final errorMessage = error.message?.toLowerCase() ?? '';
    if (errorMessage.contains('cors') || 
        errorMessage.contains('cross-origin') ||
        (error.response?.statusCode == 0 && error.type == DioExceptionType.connectionError)) {
      return 'CORS Error: The backend server needs to allow cross-origin requests. '
          'Please add CORS middleware to your FastAPI backend. '
          'See: https://fastapi.tiangolo.com/tutorial/cors/';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404) {
        return 'Resource not found.';
      } else if (statusCode == 422) {
        return 'Invalid request. Please check your input.';
      } else if (statusCode == 500) {
        return 'Server error. Please try again later.';
      } else {
        return 'Error ${statusCode}: ${error.response?.data ?? 'Unknown error'}';
      }
    } else if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to server. Please check your connection and ensure the backend is running.';
    } else {
      return 'An unexpected error occurred: ${error.message}';
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get(ApiConfig.healthEndpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> uploadPDF({
    required io.File file,
    required String name,
    required String username,
    Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'name': name,
        'username': username,
      });

      final response = await _dio.post(
        ApiConfig.uploadEndpoint,
        data: formData,
        options: Options(
          sendTimeout: ApiConfig.uploadTimeout,
          receiveTimeout: ApiConfig.uploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> uploadPDFWeb({
    required List<int> fileBytes,
    required String fileName,
    required String name,
    required String username,
    Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
        'name': name,
        'username': username,
      });

      final response = await _dio.post(
        ApiConfig.uploadEndpoint,
        data: formData,
        options: Options(
          sendTimeout: ApiConfig.uploadTimeout,
          receiveTimeout: ApiConfig.uploadTimeout,
        ),
        onSendProgress: onSendProgress,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getPDFs() async {
    try {
      final response = await _dio.get(ApiConfig.pdfsEndpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<List<PDFInfo>> getPDFsList() async {
    try {
      final data = await getPDFs();
      final pdfsList = (data['pdfs'] as List)
          .map((pdf) => PDFInfo.fromJson(pdf as Map<String, dynamic>))
          .toList();
      return pdfsList;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deletePDF(String name) async {
    try {
      final response = await _dio.delete('${ApiConfig.pdfsEndpoint}/$name');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<AskResponse> askQuestion({
    required String pdf,
    required String question,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.askEndpoint,
        data: {
          'pdf': pdf,
          'question': question,
        },
      );
      return AskResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<SummaryResponse> getSummary({
    required String pdf,
    required String type, // "page", "complete", or "chapter"
    int? pageNumber,
    String? chapter,
  }) async {
    try {
      final data = <String, dynamic>{
        'pdf': pdf,
        'type': type,
      };

      if (pageNumber != null) {
        data['page_number'] = pageNumber;
      }
      if (chapter != null) {
        data['chapter'] = chapter;
      }

      final response = await _dio.post(
        ApiConfig.summaryEndpoint,
        data: data,
      );
      return SummaryResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<QuizResponse> generateQuiz({
    required String pdf,
    required String type, // "complete" or "chapter"
    String? chapter,
    int? numQuestions,
  }) async {
    try {
      final data = <String, dynamic>{
        'pdf': pdf,
        'type': type,
      };

      if (chapter != null) {
        data['chapter'] = chapter;
      }
      if (numQuestions != null) {
        data['num_questions'] = numQuestions;
      }

      final response = await _dio.post(
        ApiConfig.quizEndpoint,
        data: data,
      );
      return QuizResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }
}
