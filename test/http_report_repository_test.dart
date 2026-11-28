import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';
import 'package:parkwise/domain/entities/spot_report.dart';
import 'package:parkwise/infrastructure/http/api_client.dart';
import 'package:parkwise/infrastructure/http/http_report_repository.dart';
import 'package:parkwise/infrastructure/storage/offline_store.dart';

void main() {
  late Directory dir;
  late Box<String> box;
  late bool online;
  late String? token;
  late List<http.Request> requests;
  late HttpReportRepository repository;
  final savedAt = DateTime(2026, 11, 24, 8, 30);

  Map<String, Object?> serverReport(String id) => {
    'id': id,
    'clientId': 'client-$id',
    'spotId': 'P2-A-14',
    'spotCode': 'A-14',
    'levelCode': 'P2',
    'kind': 'occupied',
    'note': 'A car since 8:10',
    'shownStatus': 'free',
    'reportedAt': '2026-11-24T13:14:00.000Z',
    'photoUrl': '/api/v1/reports/$id/photo',
  };

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('parkwise_report_test');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<String>('offline_${DateTime.now().microsecond}');
    online = true;
    token = 'secret-token';
    requests = [];
    final client = MockClient((request) async {
      if (!online) throw http.ClientException('offline');
      requests.add(request);
      final body = request.url.path.endsWith('/reports/mine')
          ? {
              'reports': [serverReport('r-2'), serverReport('r-1')],
            }
          : serverReport('r-3');
      return http.Response(jsonEncode(body), 200);
    });
    repository = HttpReportRepository(
      ApiClient(
        httpClient: client,
        readToken: () => token,
        baseUrl: 'https://parkwise.example.com',
      ),
      OfflineStore(box),
      () => token,
      clock: () => savedAt,
    );
  });

  tearDown(() => box.deleteFromDisk());

  test('the report goes with its photo in base64', () async {
    final photo = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
    final sent = await repository.send(
      SpotReport(
        clientId: 'client-r-3',
        spotId: 'P2-A-14',
        levelCode: 'P2',
        kind: ReportKind.occupied,
        shownStatus: SpotStatus.free,
        reportedAt: DateTime.utc(2026, 11, 24, 13, 14),
      ),
      photo: photo,
    );

    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/v1/reports');
    expect(body['photo'], base64Encode(photo));
    expect(body['shownStatus'], 'free');
    expect(sent.id, 'r-3');
    expect(sent.state, ReportState.sent);
    expect(
      sent.photoUrl,
      'https://parkwise.example.com/api/v1/reports/r-3/photo',
    );
  });

  test('my reports are kept on the phone for no signal', () async {
    final fresh = await repository.mine();
    expect(fresh.fromStorage, isFalse);
    expect(fresh.data.map((report) => report.id), ['r-2', 'r-1']);

    online = false;
    final saved = await repository.mine();

    expect(saved.fromStorage, isTrue);
    expect(saved.savedAt, savedAt);
    expect(saved.data.map((report) => report.id), ['r-2', 'r-1']);
  });

  test('the photos are asked with the session token', () {
    expect(repository.photoHeaders(), {
      'Authorization': 'Bearer secret-token',
    });
    token = null;
    expect(repository.photoHeaders(), isEmpty);
  });
}
