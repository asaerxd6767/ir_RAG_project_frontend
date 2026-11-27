import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/api_exception.dart';
import '../models/ask_response.dart';
import '../models/health_status.dart';
import '../models/library_models.dart';

/// Thin HTTP client for the documented backend contract:
/// `GET /health` -> `{"status": "ok"}` and
/// `POST /ask` -> `{"answer": "...", "sources": [...]}`.
class RagApiClient {
  RagApiClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  ApiConfig config;
  final http.Client _http;
  final Duration timeout;

  /// Reuse the same client when the user changes the base URL so controllers
  /// that hold this instance keep talking to the new backend.
  void reconfigure(ApiConfig newConfig) => config = newConfig;

  Future<HealthStatus> getHealth() async {
    final response = await _send(() => _http.get(config.endpoint('/health')));
    return _decode(
      response,
      HealthStatus.fromJson,
      fallbackMessage: 'Unexpected health response from backend.',
    );
  }

  Future<AskResponse> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      throw const ApiResponseException('Please enter a question first.');
    }

    final response = await _send(
      () => _http.post(
        config.endpoint('/ask'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{'question': trimmed}),
      ),
    );
    return _decode(
      response,
      AskResponse.fromJson,
      fallbackMessage: 'Unexpected answer response from backend.',
    );
  }

  Future<DocumentLibrary> getLibrary() {
    return _getJson('/documents', DocumentLibrary.fromJson);
  }

  Future<IngestJob> startIngest(String url) {
    return _postJson('/ingest', <String, dynamic>{
      'url': url,
    }, IngestJob.fromJson);
  }

  Future<IngestJob> getIngestJob(String jobId) {
    return _getJson(
      '/ingest/${Uri.encodeComponent(jobId)}',
      IngestJob.fromJson,
    );
  }

  Future<void> deleteDocument(String documentId) async {
    final response = await _send(
      () => _http.delete(
        config.endpoint('/documents/${Uri.encodeComponent(documentId)}'),
      ),
    );
    _decode<Map<String, dynamic>>(
      response,
      (json) => json,
      fallbackMessage: 'Unexpected delete response from backend.',
    );
  }

  Future<EvaluationSnapshot> getEvaluation() {
    return _getJson('/evaluation', EvaluationSnapshot.fromJson);
  }

  Future<T> _getJson<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _send(() => _http.get(config.endpoint(path)));
    return _decode(
      response,
      parse,
      fallbackMessage: 'Unexpected response from backend.',
    );
  }

  Future<T> _postJson<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _send(
      () => _http.post(
        config.endpoint(path),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
    return _decode(
      response,
      parse,
      fallbackMessage: 'Unexpected response from backend.',
    );
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiTimeoutException(
        'The backend took too long to respond. Please try again.',
      );
    } on Object catch (error) {
      throw ApiConnectionException(_connectionMessage(error));
    }
  }

  String _connectionMessage(Object error) {
    final uri = Uri.tryParse(config.baseUrl);
    final host = uri?.host.toLowerCase() ?? '';
    final isLoopback =
        host == '127.0.0.1' || host == 'localhost' || host == '::1';
    final hint = isLoopback
        ? ' On Android, 127.0.0.1 means the device itself, not your computer. '
              'Run adb reverse tcp:8000 tcp:8000 for a USB tunnel, use your '
              'computer’s Wi-Fi IP (e.g. http://192.168.1.10:8000), or use '
              'http://10.0.2.2:8000 in the emulator.'
        : '';
    return 'Cannot reach the backend at ${config.baseUrl}. '
        'Check that the server is running and reachable from this device. '
        '($error)$hint';
  }

  T _decode<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parse, {
    required String fallbackMessage,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiResponseException(
        _serverMessage(response),
        statusCode: response.statusCode,
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiResponseException(
        'Backend returned invalid JSON.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiResponseException(
        fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    try {
      return parse(decoded);
    } on Object {
      throw ApiResponseException(
        'Backend response is missing required fields.',
        statusCode: response.statusCode,
      );
    }
  }

  String _serverMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return _friendlyMessage(detail, response.statusCode);
        }
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } on FormatException {
      // Fall through to the generic status-code messages below.
    }

    switch (response.statusCode) {
      case 404:
        return 'Endpoint not found (404). The backend API may not be running yet.';
      case 503:
        return 'Backend is not ready (503). The index or local model may be missing.';
      default:
        return 'Backend request failed (${response.statusCode}).';
    }
  }

  String _friendlyMessage(String detail, int statusCode) {
    final lower = detail.toLowerCase();
    if (statusCode == 404 && lower.contains('not found')) {
      return 'Endpoint not found (404). The backend API may not be running yet.';
    }
    if (lower.contains('index')) {
      return 'Search index is not ready: $detail';
    }
    if (lower.contains('model')) {
      return 'Local model is not ready: $detail';
    }
    return detail;
  }

  void dispose() => _http.close();
}
