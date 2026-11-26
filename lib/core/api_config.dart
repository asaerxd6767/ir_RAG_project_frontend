import 'package:flutter/foundation.dart';

/// Base URL used when nothing is saved in the app settings.
///
/// Override at build time when needed:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
const String kDefaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// A validated, normalised base URL for the Python RAG backend.
@immutable
class ApiConfig {
  const ApiConfig._(this.baseUrl);

  final String baseUrl;

  factory ApiConfig.from(String rawUrl) {
    var value = rawUrl.trim();
    if (value.isEmpty) {
      throw const FormatException('Backend URL cannot be empty.');
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('Enter a full URL, e.g. http://127.0.0.1:8000');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw const FormatException('Only http and https URLs are supported.');
    }
    if (uri.path.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const FormatException('Use only the base URL (no path or query).');
    }

    return ApiConfig._('${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}');
  }

  Uri endpoint(String path) {
    assert(path.startsWith('/'), 'Endpoint paths must start with a slash.');
    return Uri.parse('$baseUrl$path');
  }

  @override
  String toString() => baseUrl;
}
