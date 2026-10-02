import '../../domain/errors.dart';

enum CircuitState { closed, open, halfOpen }

// despues de 3 fallas de red seguidas deja de llamar al backend por 30 s.
// asi la app no se queda esperando timeouts cuando el servidor esta caido
class CircuitBreaker {
  CircuitBreaker({
    this.failureThreshold = 3,
    this.openDuration = const Duration(seconds: 30),
    bool Function(Object error)? isFailure,
    DateTime Function()? clock,
  }) : _isFailure = isFailure ?? ((_) => true),
       _clock = clock ?? DateTime.now;

  final int failureThreshold;
  final Duration openDuration;
  final bool Function(Object error) _isFailure;
  final DateTime Function() _clock;

  int _failures = 0;
  DateTime? _openedAt;
  bool _trialInFlight = false;

  CircuitState get state {
    final openedAt = _openedAt;
    if (openedAt == null) return CircuitState.closed;
    if (_clock().difference(openedAt) >= openDuration) {
      return CircuitState.halfOpen;
    }
    return CircuitState.open;
  }

  Future<T> run<T>(Future<T> Function() action) async {
    final current = state;
    // en semiabierto solo pasa una peticion de prueba a la vez
    if (current == CircuitState.open ||
        (current == CircuitState.halfOpen && _trialInFlight)) {
      throw const CircuitOpenException();
    }

    final isTrial = current == CircuitState.halfOpen;
    if (isTrial) _trialInFlight = true;
    try {
      final result = await action();
      _close();
      return result;
    } catch (error) {
      // un 4xx quiere decir que el servidor si respondio
      if (_isFailure(error)) {
        _recordFailure(isTrial);
      } else {
        _close();
      }
      rethrow;
    } finally {
      if (isTrial) _trialInFlight = false;
    }
  }

  void _close() {
    _failures = 0;
    _openedAt = null;
  }

  void _recordFailure(bool isTrial) {
    _failures++;
    if (isTrial || _failures >= failureThreshold) _openedAt = _clock();
  }
}
