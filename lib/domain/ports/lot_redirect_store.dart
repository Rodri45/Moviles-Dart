import '../entities/lot_redirect.dart';

abstract interface class LotRedirectStore {
  Future<LotRedirect> add(String lotId, String lotName, DateTime at);

  Future<LotRedirect?> openFor(String lotId, {required DateTime since});

  Future<LotRedirect?> latest({required DateTime since});

  Future<void> answer(int id, {required bool parked, required DateTime at});

  Future<void> clear();
}
