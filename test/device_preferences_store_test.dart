import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:parkwise/infrastructure/storage/device_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory directory;
  late Box<String> box;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('parkwise-prefs');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('prefs-test');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await box.close();
    await directory.delete(recursive: true);
  });

  test('arrival time and last level persist in shared preferences', () async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final store = DevicePreferencesStore(box, sharedPreferences);
    final arrival = DateTime(2026, 10, 12, 8, 30);

    await store.saveArrivalTime(arrival);
    await store.saveLastOpenedLevel('P2');
    await store.saveDestination('eng');

    expect(store.arrivalTime, arrival);
    expect(store.lastOpenedLevel, 'P2');
    expect(store.destination, 'eng');
  });
}
