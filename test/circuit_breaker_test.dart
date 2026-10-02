import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';
import 'package:parkwise/infrastructure/http/circuit_breaker.dart';

void main() {
  late DateTime now;
  late CircuitBreaker breaker;
  late int calls;

  Future<String> ok() async {
    calls++;
    return 'ok';
  }

  Future<String> offline() async {
    calls++;
    throw const NetworkException('offline');
  }

  Future<void> failTimes(int times) async {
    for (var i = 0; i < times; i++) {
      await expectLater(breaker.run(offline), throwsA(isA<NetworkException>()));
    }
  }

  setUp(() {
    now = DateTime(2026, 10, 2, 8);
    calls = 0;
    breaker = CircuitBreaker(
      isFailure: ApiClient.isNetworkFailure,
      clock: () => now,
    );
  });

  test('closed: requests go through', () async {
    expect(await breaker.run(ok), 'ok');
    expect(breaker.state, CircuitState.closed);
    expect(calls, 1);
  });

  test('opens after 3 network failures in a row and fails fast', () async {
    await failTimes(2);
    expect(breaker.state, CircuitState.closed);

    await failTimes(1);
    expect(breaker.state, CircuitState.open);

    await expectLater(breaker.run(ok), throwsA(isA<CircuitOpenException>()));
    expect(calls, 3, reason: 'an open breaker must not touch the network');
  });

  test('a success in between resets the count', () async {
    await failTimes(2);
    await breaker.run(ok);
    await failTimes(2);
    expect(breaker.state, CircuitState.closed);
  });

  test('4xx responses do not count as network failures', () async {
    for (var i = 0; i < 5; i++) {
      await expectLater(
        breaker.run<String>(
          () async => throw const ApiException(409, 'Conflict'),
        ),
        throwsA(isA<ApiException>()),
      );
    }
    expect(breaker.state, CircuitState.closed);
  });

  test('half-open after 30 s: a successful trial closes it', () async {
    await failTimes(3);
    now = now.add(const Duration(seconds: 29));
    expect(breaker.state, CircuitState.open);

    now = now.add(const Duration(seconds: 1));
    expect(breaker.state, CircuitState.halfOpen);

    expect(await breaker.run(ok), 'ok');
    expect(breaker.state, CircuitState.closed);
  });

  test('half-open: a failed trial opens it again for 30 s', () async {
    await failTimes(3);
    now = now.add(const Duration(seconds: 30));

    await failTimes(1);
    expect(breaker.state, CircuitState.open);
    now = now.add(const Duration(seconds: 10));
    await expectLater(breaker.run(ok), throwsA(isA<CircuitOpenException>()));
  });

  test('half-open lets only one trial request through at a time', () async {
    await failTimes(3);
    now = now.add(const Duration(seconds: 30));

    final trial = breaker.run(() => Future.delayed(Duration.zero, () => 'ok'));
    await expectLater(breaker.run(ok), throwsA(isA<CircuitOpenException>()));
    expect(await trial, 'ok');
    expect(breaker.state, CircuitState.closed);
  });
}
