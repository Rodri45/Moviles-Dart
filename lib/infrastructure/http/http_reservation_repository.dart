import 'package:flutter/foundation.dart';

import '../../domain/entities/lead_time_advice.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/cached.dart';
import '../../domain/ports/reservation_repository.dart';
import '../storage/local_cache.dart';
import '../storage/reservation_history_store.dart';
import 'api_client.dart';

class HttpReservationRepository implements ReservationRepository {
  HttpReservationRepository(
    this._client,
    this._cache,
    this._historyStore,
    this._currentUserId,
  );

  static const _activeKey = 'active_reservation';

  final ApiClient _client;
  final LocalCache _cache;
  final ReservationHistoryStore _historyStore;
  final String? Function() _currentUserId;

  @override
  Future<Reservation> create(String spotId) =>
      _save(_client.post('/reservations', body: {'spotId': spotId}));

  @override
  Future<Reservation> checkIn(String reservationId) =>
      _save(_client.post('/reservations/$reservationId/check-in'));

  @override
  Future<Reservation> release(String reservationId) =>
      _save(_client.post('/reservations/$reservationId/release'));

  @override
  Future<Reservation?> active() async {
    try {
      final json = await _client.get('/reservations/active');
      final reservation = json == null
          ? null
          : Reservation.fromJson(json as Map<String, dynamic>);
      await _remember(reservation);
      return reservation;
    } catch (e) {
      final outage = ApiClient.isNetworkFailure(e);
      final saved = outage ? _cache.read(_activeKey)?.data : null;
      if (saved == null) rethrow;
      return Reservation.fromJson(saved as Map<String, dynamic>);
    }
  }

  @override
  Future<Cached<List<Reservation>>> history() async {
    final userId = _currentUserId();
    try {
      final json = await _client.get('/reservations/me') as List;
      final reservations = [
        for (final r in json) Reservation.fromJson(r as Map<String, dynamic>),
      ];
      if (userId != null) {
        try {
          await _historyStore.replace(userId, [
            for (final reservation in reservations) _toRow(reservation),
          ]);
        } catch (e) {
          debugPrint('reservation history cache write failed: $e');
        }
      }
      return Cached(reservations, savedAt: DateTime.now());
    } catch (error) {
      if (!ApiClient.isNetworkFailure(error) || userId == null) rethrow;
      final cached = await _historyStore.read(userId);
      if (cached == null) rethrow;
      return Cached(
        [
          for (final row in cached.reservations)
          Reservation.fromJson({
            'id': row['reservation_id'],
            'spotId': row['spot_id'],
            'spotCode': row['spot_code'],
            'levelCode': row['level_code'],
            'status': row['status'],
            'createdAt': row['created_at'],
            'expiresAt': row['expires_at'],
            'checkedInAt': row['checked_in_at'],
            'releasedAt': row['released_at'],
          }),
        ],
        savedAt: cached.savedAt,
        fromCache: true,
      );
    }
  }

  @override
  Future<LeadTimeAdvice> leadTime() async {
    final json = await _client.get('/recommendations/lead-time');
    return LeadTimeAdvice.fromJson(json as Map<String, dynamic>);
  }

  Future<Reservation> _save(Future<dynamic> request) async {
    final json = await request as Map<String, dynamic>;
    final reservation = Reservation.fromJson(json);
    await _remember(reservation);
    final userId = _currentUserId();
    if (userId != null) {
      try {
        await _historyStore.upsert(userId, _toRow(reservation));
      } catch (e) {
        debugPrint('reservation history cache update failed: $e');
      }
    }
    return reservation;
  }

  static Map<String, Object?> _toRow(Reservation reservation) => {
    'reservation_id': reservation.id,
    'spot_id': reservation.spotId,
    'spot_code': reservation.spotCode,
    'level_code': reservation.levelCode,
    'status': reservation.status.name,
    'created_at': reservation.createdAt.toUtc().toIso8601String(),
    'expires_at': reservation.expiresAt.toUtc().toIso8601String(),
    'checked_in_at': reservation.checkedInAt?.toUtc().toIso8601String(),
    'released_at': reservation.releasedAt?.toUtc().toIso8601String(),
  };

  Future<void> _remember(Reservation? reservation) {
    if (reservation == null || !reservation.isOpen) {
      return _cache.delete(_activeKey);
    }
    return _cache.write(_activeKey, reservation.toJson());
  }
}
