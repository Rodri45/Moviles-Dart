import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkwise/domain/errors.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';

void main() {
  test('decodes small API responses on the calling isolate', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('{"ready":true}', 200)),
      readToken: () => null,
    );

    expect(await client.get('/health'), {'ready': true});
  });

  test('decodes large API responses in a worker isolate', () async {
    final payload = List.filled(10 * 1024, 'x').join();
    final client = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"payload":"$payload"}', 200),
      ),
      readToken: () => null,
    );

    expect(await client.get('/large'), {'payload': payload});
  });

  test('reports invalid JSON consistently for both response sizes', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('{', 200)),
      readToken: () => null,
    );

    await expectLater(client.get('/invalid'), throwsA(isA<NetworkException>()));
  });
}
