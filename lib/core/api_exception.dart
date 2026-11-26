/// User-facing failures from the backend client.
///
/// Messages are written to be shown directly in the UI, so no raw stack traces
/// or technical HTTP jargon leak to the user.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiConnectionException extends ApiException {
  const ApiConnectionException(super.message);
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message);
}

class ApiResponseException extends ApiException {
  const ApiResponseException(super.message, {this.statusCode});

  final int? statusCode;
}
