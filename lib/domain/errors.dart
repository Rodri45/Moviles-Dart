// el backend respondio con un error (4xx o 5xx). message es el campo
// "error" del json
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

// no se pudo hablar con el backend: sin red, timeout, dns, etc
class NetworkException implements Exception {
  const NetworkException(this.reason);

  final String reason;

  @override
  String toString() => 'NetworkException($reason)';
}

// el circuit breaker esta abierto, ni se intento la peticion
class CircuitOpenException extends NetworkException {
  const CircuitOpenException() : super('circuit_open');
}
