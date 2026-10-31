import 'package:parkwise/domain/entities/pending_action.dart';
import 'package:parkwise/domain/ports/pending_action_store.dart';

class MemoryPendingActionStore implements PendingActionStore {
  final List<PendingAction> actions = [];
  int _nextId = 1;

  @override
  Future<int> addPending(PendingAction action) async {
    final id = _nextId++;
    actions.add(
      PendingAction(
        id: id,
        reservationId: action.reservationId,
        spotCode: action.spotCode,
        type: action.type,
        createdAt: action.createdAt,
      ),
    );
    return id;
  }

  @override
  Future<List<PendingAction>> pending() async => List.of(actions);

  @override
  Future<int> pendingCount() async => actions.length;

  @override
  Future<void> removePending(int id) async =>
      actions.removeWhere((action) => action.id == id);

  @override
  Future<void> clear() async => actions.clear();
}
