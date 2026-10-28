import '../entities/pending_action.dart';

abstract interface class PendingActionStore {
  Future<int> addPending(PendingAction action);

  Future<List<PendingAction>> pending();

  Future<int> pendingCount();

  Future<void> removePending(int id);

  Future<void> clear();
}
