import 'dart:isolate';

import '../entities/spot_filter.dart';
import '../entities/voice_query.dart';

typedef PhraseInterpreter = Future<VoiceQuery> Function(String phrase);

Future<VoiceQuery> interpretPhraseInBackground(String phrase) =>
    Isolate.run(() => interpretPhrase(phrase), debugName: 'voice-query');

Future<VoiceQuery> interpretPhraseInline(String phrase) async =>
    interpretPhrase(phrase);

VoiceQuery interpretPhrase(String phrase) {
  final words = _words(phrase);
  final text = words.join(' ');
  final code = _spotCode.firstMatch(text);
  final levelMatch = _level.firstMatch(text);
  final level = code?.group(1) ?? levelMatch?.group(1) ?? levelMatch?.group(2);
  final zone =
      code?.group(2)?.toUpperCase() ??
      _zoneLetters[_zone.firstMatch(text)?.group(1)];
  final number = code?.group(3) ?? _spotNumber.firstMatch(text)?.group(1);

  return VoiceQuery(
    levelCode: level == null ? null : 'P$level',
    zone: zone,
    spotNumber: zone == null || number == null ? null : int.parse(number),
    filters: {
      SpotFilter.available,
      for (final entry in _filterStems.entries)
        if (words.any((word) => entry.value.any(word.startsWith))) entry.key,
    },
  );
}

final _spotCode = RegExp(r'\bp ?([1-3]) ?([abc]) ?(\d{1,2})\b');

final _level = RegExp(
  r'\b(?:p|pe|piso|nivel|level|floor|planta) ?([1-3])\b'
  r'|\b([1-3]) ?(?:piso|nivel|level|floor|planta)\b',
);

final _zone = RegExp(r'\b(?:zona|zone) (a|b|c|be|ce|bee|see)\b');

final _spotNumber = RegExp(
  r'\b(?:puesto|plaza|spot|space|numero|number|zona [a-z]+|zone [a-z]+) '
  r'(\d{1,2})\b',
);

const _zoneLetters = {
  'a': 'A',
  'b': 'B',
  'c': 'C',
  'be': 'B',
  'ce': 'C',
  'bee': 'B',
  'see': 'C',
};

const _filterStems = {
  SpotFilter.electric: ['electr', 'charg', 'carga', 'recarg'],
  SpotFilter.accessible: [
    'accesib',
    'accessib',
    'discapac',
    'disab',
    'movilidad',
    'wheelchair',
  ],
  SpotFilter.vip: ['vip'],
};

const _replacements = {
  'ev': 'electric',
  'uno': '1',
  'primer': '1',
  'primero': '1',
  'one': '1',
  'first': '1',
  'dos': '2',
  'segundo': '2',
  'two': '2',
  'second': '2',
  'tres': '3',
  'tercer': '3',
  'tercero': '3',
  'three': '3',
  'third': '3',
  'cuatro': '4',
  'four': '4',
  'cinco': '5',
  'five': '5',
  'seis': '6',
  'six': '6',
  'siete': '7',
  'seven': '7',
  'ocho': '8',
  'eight': '8',
  'nueve': '9',
  'nine': '9',
  'diez': '10',
  'ten': '10',
};

const _accents = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

final _separators = RegExp(r'[^a-z0-9]+');

List<String> _words(String phrase) {
  final lower = phrase.toLowerCase();
  final plain = [for (final char in lower.split('')) _accents[char] ?? char]
      .join()
      .replaceAll(_separators, ' ');
  return [
    for (final word in plain.split(' '))
      if (word.isNotEmpty) _replacements[word] ?? word,
  ];
}
