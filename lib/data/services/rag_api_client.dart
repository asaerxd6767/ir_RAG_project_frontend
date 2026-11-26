import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api_config.dart';
import '../../core/api_exception.dart';
import '../models/ask_response.dart';
import '../models/health_status.dart';

/// Thin HTTP client for the documented backend contract:
/// `GET /health` -> `{"status": "ok"}` and
/// `POST /ask` -> `{"answer": "...", "sources": [...]}`.
class RagApiClient {
  RagApiClient({
    required this.config,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  final ApiConfig config;
  final http.Client _http;
  final Duration timeout;

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

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiTimeoutException(
        'The backend took too long to respond. Please try again.',
      );
    } on Object catch (error) {
      throw ApiConnectionException(
        'Cannot reach the backend at ${config.baseUrl}. '
        'Check that the server is running. ($error)',
      );
    }
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
      throw ApiResponseException(fallbackMessage, statusCode: response.statusCode);
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
