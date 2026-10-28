import '../../domain/entities/lot_redirect.dart';
import '../../domain/ports/lot_redirect_store.dart';

class MemoryLotRedirectStore implements LotRedirectStore {
  final List<LotRedirect> redirects = [];

  @override
  Future<LotRedirect> add(String lotId, String lotName, DateTime at) async {
    final redirect = LotRedirect(
      id: redirects.length + 1,
      lotId: lotId,
      lotName: lotName,
      redirectedAt: at,
    );
    redirects.add(redirect);
    return redirect;
  }

  @override
  Future<LotRedirect?> openFor(String lotId, {required DateTime since}) async =>
      _newest(
        (r) =>
            r.lotId == lotId &&
            !r.redirectedAt.isBefore(since) &&
            !r.answered,
      );

  @override
  Future<LotRedirect?> latest({required DateTime since}) async =>
      _newest((r) => !r.redirectedAt.isBefore(since));

  @override
  Future<void> answer(
    int id, {
    required bool parked,
    required DateTime at,
  }) async {
    final index = redirects.indexWhere((r) => r.id == id);
    final old = redirects[index];
    redirects[index] = LotRedirect(
      id: old.id,
      lotId: old.lotId,
      lotName: old.lotName,
      redirectedAt: old.redirectedAt,
      answeredAt: at,
      parked: parked,
    );
  }

  @override
  Future<void> clear() async => redirects.clear();

  LotRedirect? _newest(bool Function(LotRedirect) test) {
    final matches = redirects.where(test).toList()
      ..sort((a, b) => b.redirectedAt.compareTo(a.redirectedAt));
    return matches.isEmpty ? null : matches.first;
  }
}
