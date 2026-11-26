import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/client_id.dart';
import '../../../domain/entities/parking_spot.dart';
import '../../../domain/entities/report_photo.dart';
import '../../../domain/entities/spot_report.dart';
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
    this._preferences, {
    this._compress = compressPhotoInBackground,
    this._newId = newClientId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ReportRepository _reports;
  final PhotoSource _camera;
  final ParkingRepository _parking;
  final PreferencesStore _preferences;
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

  void start({ParkingSpot? spot}) {
    this.spot = spot;
    kind = ReportKind.occupied;
    note = '';
    photo = null;
    errorMessage = null;
    notifyListeners();
  }

  void chooseSpot(ParkingSpot value) {
    spot = value;
    notifyListeners();
  }

  void chooseKind(ReportKind value) {
    kind = value;
    notifyListeners();
  }

  void changeNote(String value) {
    note = value;
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
    try {
      photo = await _compress(original);
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
          start();
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
}
