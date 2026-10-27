import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/core/design/palette.dart';
import 'package:parkwise/core/widgets/spot_cell.dart';
import 'package:parkwise/domain/entities/parking_spot.dart';

void main() {
  const spot = ParkingSpot(
    id: 'P1-A-01',
    code: 'A-01',
    zone: 'A',
    levelCode: 'P1',
    status: SpotStatus.free,
    walkMinutes: 2,
  );

  testWidgets('shows the parking spot code inside the cell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SpotCell(spot: spot)),
      ),
    );

    expect(find.text('A-01'), findsOneWidget);
  });

  testWidgets('highlights a spot matching the selected category', (
    tester,
  ) async {
    const categoryColor = Palette.secondary;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpotCell(spot: spot, highlightColor: categoryColor),
        ),
      ),
    );

    final cell = tester.widget<Material>(
      find.descendant(
        of: find.byType(SpotCell),
        matching: find.byType(Material),
      ),
    );

    expect(
      cell.color,
      Color.alphaBlend(
        categoryColor.withValues(alpha: 0.12),
        Palette.successSoft,
      ),
    );
    expect((cell.shape as RoundedRectangleBorder).side.color, categoryColor);
    expect((cell.shape as RoundedRectangleBorder).side.width, 2.5);
  });

  testWidgets('distinguishes unavailable spots from occupied spots', (
    tester,
  ) async {
    const unavailableSpot = ParkingSpot(
      id: 'P1-A-02',
      code: 'A-02',
      zone: 'A',
      levelCode: 'P1',
      status: SpotStatus.disabled,
      walkMinutes: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SpotCell(spot: unavailableSpot),
              SpotCell(
                spot: ParkingSpot(
                  id: 'P1-A-03',
                  code: 'A-03',
                  zone: 'A',
                  levelCode: 'P1',
                  status: SpotStatus.occupied,
                  walkMinutes: 2,
                ),
              ),
              SpotLegend(),
            ],
          ),
        ),
      ),
    );

    final unavailableCell = tester.widget<Material>(
      find
          .descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is SpotCell && widget.spot == unavailableSpot,
            ),
            matching: find.byType(Material),
          )
          .first,
    );
    final occupiedCell = tester.widget<Material>(
      find
          .descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is SpotCell &&
                  widget.spot.status == SpotStatus.occupied,
            ),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(unavailableCell.color, Palette.inputFill);
    expect(occupiedCell.color, Palette.surface);
    expect(find.text('Unavailable'), findsOneWidget);
  });
}
