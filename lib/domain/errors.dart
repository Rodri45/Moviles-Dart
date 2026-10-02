class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

class NetworkException implements Exception {
  const NetworkException(this.reason);

  final String reason;

  @override
  String toString() => 'NetworkException($reason)';
}

class CircuitOpenException extends NetworkException {
  const CircuitOpenException() : super('circuit_open');
}
