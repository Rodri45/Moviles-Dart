import '../../domain/errors.dart';

String errorTypeFor(Object error) {
  if (error is CircuitOpenException) return 'circuit_open';
  if (error is NetworkException) {
    return error.reason == 'timeout' ? 'timeout' : 'network';
  }
  if (error is ApiException) return 'http_${error.statusCode}';
  return 'unknown';
}

String errorMessageFor(Object error) {
  if (error is CircuitOpenException) {
    return 'The server is not responding. We\'ll try again in a moment.';
  }
  if (error is NetworkException) {
    return 'No connection. Check your internet and try again.';
  }
  if (error is ApiException && error.statusCode >= 500) {
    return 'The server had a problem. Try again.';
  }
  if (error is ApiException) return error.message;
  return 'Something went wrong. Try again.';
}
