import '../../core/cache/array_map_cache.dart';
import '../../domain/entities/lead_time_advice.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/saved.dart';
import '../../domain/ports/reservation_repository.dart';

class HistoryMemoryCache implements ReservationRepository {
  HistoryMemoryCache(
    this._inner,
    this._userId, {
    ArrayMapCache<String, Saved<List<Reservation>>>? memory,
  }) : _memory =
           memory ?? ArrayMapCache(maxEntries: maxUsers, ttl: timeToLive);

  static const maxUsers = 4;

  static const timeToLive = Duration(seconds: 60);

  final ReservationRepository _inner;
  final String? Function() _userId;
  final ArrayMapCache<String, Saved<List<Reservation>>> _memory;

  @override
  Future<Saved<List<Reservation>>> history() async {
    final user = _userId();
    if (user == null) return _inner.history();
    final remembered = _memory.get(user);
    if (remembered != null) return remembered;
    final result = await _inner.history();
    if (!result.fromStorage) _memory.put(user, result);
    return result;
  }

  @override
  Future<Reservation> create(String spotId) =>
      _forgetAfter(_inner.create(spotId));

  @override
  Future<Reservation> checkIn(String reservationId) =>
      _forgetAfter(_inner.checkIn(reservationId));

  @override
  Future<Reservation> release(String reservationId) =>
      _forgetAfter(_inner.release(reservationId));

  @override
  Future<Reservation?> active() => _inner.active();

  @override
  Future<LeadTimeAdvice> leadTime() => _inner.leadTime();

  Future<Reservation> _forgetAfter(Future<Reservation> change) async {
    final reservation = await change;
    final user = _userId();
    if (user != null) _memory.remove(user);
    return reservation;
  }
}
