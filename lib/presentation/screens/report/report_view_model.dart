import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/client_id.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/report_photo.dart';
import '../../../domain/entities/spot_report.dart';
import '../../../domain/ports/form_draft_store.dart';
import '../../../domain/ports/parking_repository.dart';
import '../../../domain/ports/photo_source.dart';
import '../../../domain/ports/preferences_store.dart';
import '../../../domain/ports/report_repository.dart';
import '../../../domain/services/photo_compression.dart';
import '../../shared/error_messages.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel(
    this._reports,
    this._camera,
    this._parking,
    this._preferences,
    this._drafts, {
    this._compress = compressPhotoInBackground,
    this._newId = newClientId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const draftForm = 'report';

  final ReportRepository _reports;
  final PhotoSource _camera;
  final ParkingRepository _parking;
  final PreferencesStore _preferences;
  final FormDraftStore _drafts;
  final PhotoCompressor _compress;
  final String Function() _newId;
  final DateTime Function() _clock;

  ParkingSpot? spot;
  ReportKind kind = ReportKind.occupied;
  String note = '';
  ReportPhoto? photo;
  bool isCompressing = false;
  bool isSending = false;
  String? errorMessage;

  bool get canSend => spot != null && !isCompressing && !isSending;

  ReportKind get _lastKind {
    final code = _preferences.lastReportKind;
    return code == null ? ReportKind.occupied : ReportKind.fromCode(code);
  }

  void start({ParkingSpot? spot}) {
    final draft = _drafts.read(draftForm);
    final drafted = _spotOf(draft);
    final keepDraft = spot == null || spot.id == drafted?.id;
    this.spot = spot ?? drafted;
    kind = keepDraft && draft['kind'] != null
        ? ReportKind.fromCode(draft['kind'])
        : _lastKind;
    note = keepDraft ? draft['note'] ?? '' : '';
    if (!keepDraft) photo = null;
    errorMessage = null;
    notifyListeners();
  }

  void chooseSpot(ParkingSpot value) {
    spot = value;
    _saveDraft();
    notifyListeners();
  }

  void chooseKind(ReportKind value) {
    kind = value;
    _saveDraft();
    notifyListeners();
  }

  void changeNote(String value) {
    note = value;
    _saveDraft();
  }

  Future<List<ParkingSpot>> spotsOf(String levelCode) async {
    final result = await _parking.getSpots(
      levelCode,
      destination: _preferences.destination,
    );
    return result.data;
  }

  Future<void> takePhoto() async {
    errorMessage = null;
    Uint8List? original;
    try {
      original = await _camera.takePhoto();
    } catch (e) {
      debugPrint('camera failed: $e');
      errorMessage = 'The camera could not be opened.';
      notifyListeners();
      return;
    }
    if (original == null) return;
    isCompressing = true;
    notifyListeners();
    final watch = Stopwatch()..start();
    try {
      final compressed = await _compress(original);
      photo = compressed;
      debugPrint(
        'photo ready in ${watch.elapsedMilliseconds} ms: '
        '${original.length ~/ 1024} KB to ${compressed.sizeBytes ~/ 1024} KB',
      );
    } catch (e) {
      debugPrint('photo not compressed: $e');
      errorMessage = 'The photo could not be read. Take it again.';
    }
    isCompressing = false;
    notifyListeners();
  }

  void removePhoto() {
    photo = null;
    notifyListeners();
  }

  Future<SpotReport?> send() {
    final chosen = spot;
    if (chosen == null || !canSend) return Future.value();
    isSending = true;
    errorMessage = null;
    notifyListeners();
    final trimmed = note.trim();
    final report = SpotReport(
      clientId: _newId(),
      spotId: chosen.id,
      levelCode: chosen.levelCode,
      kind: kind,
      shownStatus: chosen.status,
      reportedAt: _clock(),
      note: trimmed.isEmpty ? null : trimmed,
    );
    return _reports
        .send(report, photo: photo?.bytes)
        .then<SpotReport?>((saved) {
          _finish(report.kind);
          return saved;
        })
        .catchError((Object e) {
          errorMessage = errorMessageFor(e);
          return null;
        })
        .whenComplete(() {
          isSending = false;
          notifyListeners();
        });
  }

  void _finish(ReportKind used) {
    unawaited(
      _preferences
          .saveLastReportKind(used.code)
          .catchError((Object e) => debugPrint('kind not saved: $e')),
    );
    unawaited(
      _drafts
          .clear(draftForm)
          .catchError((Object e) => debugPrint('draft not cleared: $e')),
    );
    spot = null;
    kind = used;
    note = '';
    photo = null;
  }

  void _saveDraft() {
    final chosen = spot;
    unawaited(
      _drafts
          .save(draftForm, {
            if (chosen != null) ...{
              'spotId': chosen.id,
              'spotCode': chosen.code,
              'zone': chosen.zone,
              'levelCode': chosen.levelCode,
              'status': chosen.status.name,
            },
            'kind': kind.code,
            'note': note,
          })
          .catchError((Object e) => debugPrint('draft not saved: $e')),
    );
  }

  static ParkingSpot? _spotOf(Map<String, String> draft) {
    final id = draft['spotId'];
    final level = draft['levelCode'];
    if (id == null || level == null) return null;
    return ParkingSpot(
      id: id,
      code: draft['spotCode'] ?? id,
      zone: draft['zone'] ?? '',
      levelCode: level,
      status: SpotStatus.values.asNameMap()[draft['status']] ?? SpotStatus.free,
      walkMinutes: 0,
    );
  }
}
