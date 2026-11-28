import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/ports/connectivity_port.dart';
import 'package:parkwise/infrastructure/mock/mock_connectivity.dart';
import 'package:parkwise/presentation/shared/connectivity_aware.dart';

class _Screen extends ChangeNotifier with ConnectivityAware {
  _Screen(ConnectivityPort connectivity, this._liveFromLoad) {
    watchConnectivity(connectivity, load);
  }

  final int _liveFromLoad;
  int loads = 0;
  bool saved = true;

  @override
  bool get showingSavedData => saved;

  Future<void> load() async {
    loads++;
    saved = loads < _liveFromLoad;
  }
}

void main() {
  Future<_Screen> offlineScreen(
    MockConnectivity connectivity,
    int liveFrom,
  ) async {
    final screen = _Screen(connectivity, liveFrom);
    addTearDown(screen.dispose);
    await Future<void>.delayed(Duration.zero);
    return screen;
  }

  test('reloads by itself when the signal comes back', () async {
    final connectivity = MockConnectivity(online: false);
    final screen = await offlineScreen(connectivity, 1);

    connectivity.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(screen.loads, 1);
    expect(screen.showingSavedData, isFalse);
  });

  test('keeps trying until the data is live again', () async {
    final connectivity = MockConnectivity(online: false);
    final screen = await offlineScreen(connectivity, 2);

    connectivity.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(screen.loads, 1);
    expect(screen.showingSavedData, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(screen.loads, 2);
    expect(screen.showingSavedData, isFalse);
  });

  test('stops trying when the signal drops again', () async {
    final connectivity = MockConnectivity(online: false);
    final screen = await offlineScreen(connectivity, 99);

    connectivity.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    connectivity.setOnline(false);
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(screen.loads, 1);
  });
}
