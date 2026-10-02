import '../../domain/entities/lead_time_advice.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/ports/reservation_repository.dart';
import '../storage/local_cache.dart';
import 'api_client.dart';

// reservas contra el backend. la reserva abierta se guarda en hive para
// poder mostrarla en la pantalla de offline
class HttpReservationRepository implements ReservationRepository {
  HttpReservationRepository(this._client, this._cache);

  static const _activeKey = 'active_reservation';

  final ApiClient _client;
  final LocalCache _cache;

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
      // sin red o con el servidor caido se usa la ultima que se vio
      final outage = ApiClient.isNetworkFailure(e);
      final saved = outage ? _cache.read(_activeKey)?.data : null;
      if (saved == null) rethrow;
      return Reservation.fromJson(saved as Map<String, dynamic>);
    }
  }

  @override
  Future<List<Reservation>> history() async {
    final json = await _client.get('/reservations/me') as List;
    return [
      for (final r in json) Reservation.fromJson(r as Map<String, dynamic>),
    ];
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
    return reservation;
  }

  Future<void> _remember(Reservation? reservation) {
    if (reservation == null || !reservation.isOpen) {
      return _cache.delete(_activeKey);
    }
    return _cache.write(_activeKey, reservation.toJson());
  }
}
