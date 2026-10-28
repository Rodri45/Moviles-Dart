import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/infrastructure/mock/memory_lot_redirect_store.dart';
import 'package:parkwise/infrastructure/mock/mock_telemetry.dart';
import 'package:parkwise/infrastructure/mock/parking_mock_data.dart';
import 'package:parkwise/presentation/screens/no_spots/lot_arrival_view_model.dart';

void main() {
  final parkCentral = ParkingMockData.nearbyLots.first;
  late DateTime now;
  late MemoryLotRedirectStore store;
  late MockTelemetry telemetry;
  late LotArrivalViewModel arrival;

  setUp(() {
    now = DateTime.utc(2026, 10, 28, 13);
    store = MemoryLotRedirectStore();
    telemetry = MockTelemetry();
    arrival = LotArrivalViewModel(store, telemetry, clock: () => now);
  });

  test('navigate saves the redirect and asks about that lot', () async {
    await arrival.redirected(parkCentral);

    expect(telemetry.named('lot_redirected').single, {'lotId': 'nearby-1'});
    expect(arrival.question?.lotName, 'Park Central');
  });

  test('tapping navigate twice on the same lot counts one redirect', () async {
    await arrival.redirected(parkCentral);
    now = now.add(const Duration(minutes: 3));
    await arrival.redirected(parkCentral);

    expect(store.redirects, hasLength(1));
    expect(telemetry.named('lot_redirected'), hasLength(1));
  });

  test('the answer sends the minutes since the redirect', () async {
    await arrival.redirected(parkCentral);
    now = now.add(const Duration(minutes: 18));

    await arrival.answer(parked: true);

    expect(telemetry.named('lot_arrival_confirmed').single, {
      'lotId': 'nearby-1',
      'parked': true,
      'minutesAfter': 18,
    });
    expect(arrival.question, isNull);
    expect(store.redirects.single.parked, isTrue);
  });

  test('an answered redirect is not asked again', () async {
    await arrival.redirected(parkCentral);
    await arrival.answer(parked: false);

    await arrival.load();

    expect(arrival.question, isNull);
  });

  test('after six hours the question is not shown', () async {
    await arrival.redirected(parkCentral);
    now = now.add(const Duration(hours: 6, minutes: 1));

    await arrival.load();

    expect(arrival.question, isNull);
  });

  test('signing out deletes the saved redirects', () async {
    await arrival.redirected(parkCentral);

    await arrival.clear();

    expect(store.redirects, isEmpty);
    expect(arrival.question, isNull);
  });
}
