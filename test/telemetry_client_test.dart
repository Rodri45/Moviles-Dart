import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';
import 'package:parkwise/infrastructure/http/telemetry_client.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';

void main() {
  late Directory directory;
  late Box<String> queue;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('parkwise-telemetry');
    Hive.init(directory.path);
    queue = await Hive.openBox<String>('telemetry-test');
  });

  tearDown(() async {
    await queue.close();
    await directory.delete(recursive: true);
  });

  test('queued Android events preserve their platform and occurrence time', () async {
    final client = ApiClient(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      readToken: () => null,
    );
    final telemetry = TelemetryClient(
      client,
      queue,
      MockConnectivity(online: false),
    );

    telemetry.track('forecast_viewed', {'platform': 'ios'});
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final event = jsonDecode(queue.getAt(0)!) as Map<String, dynamic>;
    final properties = event['properties'] as Map<String, dynamic>;
    expect(properties['platform'], 'android');
    expect(DateTime.tryParse(properties['occurredAt'] as String), isNotNull);
  });
}
