import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkwise/core/widgets/lot_photo.dart';
import 'package:parkwise/domain/entities/nearby_lot.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Map<String, dynamic> lot({String? imageUrl}) => {
    'id': 'nearby-1',
    'name': 'Park Central',
    'address': 'Calle ejercito 18',
    'ratePerHour': 6000,
    'currency': 'COP',
    'walkMinutes': 6,
    'imageUrl': imageUrl,
  };

  test('the photo path of the backend becomes a full address', () {
    final parsed = NearbyLot.fromJson(
      lot(imageUrl: '/images/nearby-1.jpg'),
      imageBase: 'https://parkwise.example.com',
    );

    expect(parsed.imageUrl, 'https://parkwise.example.com/images/nearby-1.jpg');
  });

  test('a lot without photo keeps imageUrl empty', () {
    final parsed = NearbyLot.fromJson(
      lot(),
      imageBase: 'https://parkwise.example.com',
    );

    expect(parsed.imageUrl, isNull);
  });

  testWidgets('a lot without photo shows its initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LotPhoto(name: 'Park Central', url: null)),
      ),
    );

    expect(find.text('PC'), findsOneWidget);
  });
}
