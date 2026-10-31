import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/cached.dart';
import '../../domain/entities/lead_time_advice.dart';
import '../../domain/entities/pending_action.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/errors.dart';
import '../../domain/ports/connectivity_port.dart';
import '../../domain/ports/pending_action_store.dart';
import '../../domain/ports/reservation_outbox.dart';
import '../../domain/ports/reservation_repository.dart';
import 'api_client.dart';

typedef RememberReservation = Future<void> Function(Reservation reservation);

class OutboxReservationRepository
    implements ReservationRepository, ReservationOutbox {
  OutboxReservationRepository(
    this._inner,
    this._store,
    ConnectivityPort connectivity, {
    RememberReservation? remember,
    DateTime Function()? clock,
  }) : _remember = remember ?? ((_) async {}),
       _clock = clock ?? DateTime.now {
    _connectivitySub = connectivity.changes
        .where((online) => online)
        .listen((_) => flush());
  }

  final ReservationRepository _inner;
  final PendingActionStore _store;
  final RememberReservation _remember;
  final DateTime Function() _clock;
  final _status = StreamController<OutboxStatus>.broadcast();
  late final StreamSubscription<bool> _connectivitySub;
  Future<OutboxStatus>? _running;

  @override
  Stream<OutboxStatus> get status => _status.stream;

  @override
  Future<int> pendingCount() => _store.pendingCount();

  @override
  Future<Reservation> create(String spotId) => _inner.create(spotId);

  @override
  Future<Reservation?> active() => _inner.active();

  @override
  Future<LeadTimeAdvice> leadTime() => _inner.leadTime();

  @override
  Future<Reservation> checkIn(String reservationId) => _sendOrQueue(
    reservationId,
    PendingActionType.checkIn,
    () => _inner.checkIn(reservationId),
    (open) => _copy(
      open,
      status: ReservationStatus.fulfilled,
      checkedInAt: _clock(),
    ),
  );

  @override
  Future<Reservation> release(String reservationId) => _sendOrQueue(
    reservationId,
    PendingActionType.release,
    () => _inner.release(reservationId),
    (open) => _copy(
      open,
      status: open.status == ReservationStatus.fulfilled
          ? ReservationStatus.released
          : ReservationStatus.cancelled,
      releasedAt: _clock(),
    ),
  );

  @override
  Future<Cached<List<Reservation>>> history() => _inner.history();

  @override
  Future<OutboxStatus> flush() =>
      _running ??= _flush().whenComplete(() => _running = null);

  @override
  Future<void> clear() async {
    await _store.clear();
    _status.add(OutboxStatus.idle);
  }

  Future<Reservation> _sendOrQueue(
    String reservationId,
    PendingActionType type,
    Future<Reservation> Function() send,
    Reservation Function(Reservation open) expected,
  ) async {
    if (await _store.pendingCount() > 0) await flush();
    if (await _store.pendingCount() == 0) {
      try {
        return await send();
      } catch (e) {
        if (!ApiClient.isNetworkFailure(e)) rethrow;
      }
    }
    final open = await _openReservation(reservationId);
    if (open == null) throw const NetworkException('offline_without_copy');
    await _store.addPending(
      PendingAction(
        reservationId: reservationId,
        spotCode: open.spotCode,
        type: type,
        createdAt: _clock(),
      ),
    );
    final result = expected(open);
    await _remember(result);
    _status.add(OutboxStatus(pending: await _store.pendingCount()));
    return result;
  }

  Future<OutboxStatus> _flush() async {
    final rejected = <String>[];
    final actions = await _store.pending();
    for (final action in actions) {
      try {
        if (action.type == PendingActionType.checkIn) {
          await _inner.checkIn(action.reservationId);
        } else {
          await _inner.release(action.reservationId);
        }
        await _store.removePending(action.id!);
      } catch (e) {
        if (ApiClient.isNetworkFailure(e)) break;
        await _store.removePending(action.id!);
        rejected.add(_rejectionMessage(action, e));
        debugPrint('outbox action ${action.id} rejected: $e');
      }
    }
    final status = OutboxStatus(
      pending: await _store.pendingCount(),
      rejected: rejected,
    );
    _status.add(status);
    return status;
  }

  Future<Reservation?> _openReservation(String reservationId) async {
    try {
      final open = await _inner.active();
      return open?.id == reservationId ? open : null;
    } catch (_) {
      return null;
    }
  }

  static String _rejectionMessage(PendingAction action, Object error) {
    final what = action.type == PendingActionType.checkIn
        ? '"I parked" for spot ${action.spotCode}'
        : '"I left" for spot ${action.spotCode}';
    final message = error is ApiException ? error.message.toLowerCase() : '';
    if (message.contains('expired')) {
      return '$what reached the server after the hold expired.';
    }
    return '$what could not be saved on the server.';
  }

  static Reservation _copy(
    Reservation open, {
    required ReservationStatus status,
    DateTime? checkedInAt,
    DateTime? releasedAt,
  }) => Reservation(
    id: open.id,
    spotId: open.spotId,
    spotCode: open.spotCode,
    levelCode: open.levelCode,
    status: status,
    createdAt: open.createdAt,
    expiresAt: open.expiresAt,
    checkedInAt: checkedInAt ?? open.checkedInAt,
    releasedAt: releasedAt ?? open.releasedAt,
  );

  void dispose() {
    _connectivitySub.cancel();
    _status.close();
  }
}
