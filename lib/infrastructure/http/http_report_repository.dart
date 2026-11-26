import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/saved.dart';
import '../../domain/entities/spot_report.dart';
import '../../domain/ports/report_repository.dart';
import '../storage/offline_store.dart';
import 'api_client.dart';

class HttpReportRepository implements ReportRepository {
  HttpReportRepository(
    this._client,
    this._offline,
    this._readToken, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _mineKey = 'reports:mine';

  final ApiClient _client;
  final OfflineStore _offline;
  final String? Function() _readToken;
  final DateTime Function() _clock;

  @override
  Future<SpotReport> send(SpotReport report, {Uint8List? photo}) async {
    final json = await _client.post(
      '/reports',
      body: report.toJson(photo: photo == null ? null : base64Encode(photo)),
    );
    return SpotReport.fromJson(
      json as Map<String, dynamic>,
      imageBase: _client.baseUrl,
    );
  }

  @override
  Future<Saved<List<SpotReport>>> mine() async {
    try {
      final json = await _client.get('/reports/mine');
      final reports = _parse(json);
      final savedAt = _clock();
      await _offline.write(_mineKey, json, savedAt: savedAt);
      return Saved(reports, savedAt: savedAt);
    } catch (e) {
      final entry = ApiClient.isNetworkFailure(e)
          ? _offline.read(_mineKey)
          : null;
      if (entry == null) rethrow;
      return Saved(
        _parse(entry.data),
        savedAt: entry.savedAt,
        fromStorage: true,
      );
    }
  }

  @override
  Map<String, String> photoHeaders() {
    final token = _readToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  List<SpotReport> _parse(Object? json) => [
    for (final item in (json as Map<String, dynamic>)['reports'] as List)
      SpotReport.fromJson(
        item as Map<String, dynamic>,
        imageBase: _client.baseUrl,
      ),
  ];
}
