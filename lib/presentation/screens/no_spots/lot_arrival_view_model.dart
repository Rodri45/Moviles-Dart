import 'package:flutter/foundation.dart';

import '../../../domain/entities/lot_redirect.dart';
import '../../../domain/entities/nearby_lot.dart';
import '../../../domain/ports/lot_redirect_store.dart';
import '../../../domain/ports/telemetry.dart';

class LotArrivalViewModel extends ChangeNotifier {
  LotArrivalViewModel(
    this._store,
    this._telemetry, {
    this.askFor = const Duration(hours: 6),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LotRedirectStore _store;
  final Telemetry _telemetry;
  final Duration askFor;
  final DateTime Function() _clock;

  LotRedirect? question;

  DateTime get _since => _clock().subtract(askFor);

  Future<void> load() async {
    try {
      final latest = await _store.latest(since: _since);
      question = latest == null || latest.answered ? null : latest;
    } catch (e) {
      debugPrint('arrival question failed: $e');
      question = null;
    }
    notifyListeners();
  }

  Future<void> redirected(NearbyLot lot) async {
    final open = await _store.openFor(lot.id, since: _since);
    if (open == null) {
      await _store.add(lot.id, lot.name, _clock());
      _telemetry.track('lot_redirected', {'lotId': lot.id});
    }
    await load();
  }

  Future<void> answer({required bool parked}) async {
    final redirect = question;
    if (redirect == null) return;
    final now = _clock();
    question = null;
    notifyListeners();
    await _store.answer(redirect.id, parked: parked, at: now);
    _telemetry.track('lot_arrival_confirmed', {
      'lotId': redirect.lotId,
      'parked': parked,
      'minutesAfter': now.difference(redirect.redirectedAt).inMinutes,
    });
  }

  Future<void> clear() async {
    question = null;
    notifyListeners();
    await _store.clear();
  }
}
