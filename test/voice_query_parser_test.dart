import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/entities/spot_filter.dart';
import 'package:parkwise/domain/services/voice_query_parser.dart';

void main() {
  test('a spanish phrase finds the level and the type of spot', () {
    final query = interpretPhrase('Puesto eléctrico en el P2');

    expect(query.levelCode, 'P2');
    expect(query.filters, {SpotFilter.available, SpotFilter.electric});
    expect(query.searchText, 'P2');
    expect(query.understood, isTrue);
  });

  test('an english phrase finds the zone and the type of spot', () {
    final query = interpretPhrase('Accessible spot in zone B');

    expect(query.levelCode, isNull);
    expect(query.zone, 'B');
    expect(query.filters, {SpotFilter.available, SpotFilter.accessible});
    expect(query.searchText, 'B');
  });

  test('numbers and letters said as words are understood', () {
    expect(interpretPhrase('pe dos zona be').searchText, 'P2 B');
    expect(interpretPhrase('segundo piso').levelCode, 'P2');
    expect(interpretPhrase('spot on the third floor').levelCode, 'P3');
    expect(interpretPhrase('EV P3').filters, contains(SpotFilter.electric));
    expect(interpretPhrase('VIP en P1').filters, contains(SpotFilter.vip));
  });

  test('a full spot code becomes the code of the spot', () {
    expect(interpretPhrase('P2-B-14').searchText, 'P2 B B-14');

    final spoken = interpretPhrase('puesto 7 de la zona C en el nivel 3');
    expect(spoken.levelCode, 'P3');
    expect(spoken.spotCode, 'C-07');
    expect(spoken.searchText, 'P3 C C-07');
  });

  test('a number without a zone is not taken as a spot', () {
    final query = interpretPhrase('spot 14 in P2');

    expect(query.spotCode, isNull);
    expect(query.searchText, 'P2');
  });

  test('a phrase without a level, zone or type is not understood', () {
    final query = interpretPhrase('hola, cómo estás');

    expect(query.understood, isFalse);
    expect(query.filters, {SpotFilter.available});
    expect(query.searchText, isEmpty);
  });

  test('the background isolate gives the same answer', () async {
    final background = await interpretPhraseInBackground('electric P2 zone A');
    final inline = interpretPhrase('electric P2 zone A');

    expect(background.searchText, inline.searchText);
    expect(background.filters, inline.filters);
  });
}
