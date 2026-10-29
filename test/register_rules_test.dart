import 'package:flutter_test/flutter_test.dart';
import 'package:parkwise/domain/services/register_rules.dart';

void main() {
  group('name', () {
    test('accepts letters, accents, apostrophes, dots and hyphens', () {
      const names = ['Laura Gómez', 'Ana-María', "D'Angelo", 'J. Pérez'];
      for (final name in names) {
        expect(RegisterRules.nameProblem(name), isNull, reason: name);
      }
    });

    test('rejects what the backend rejects', () {
      for (final name in [
        'L',
        'A' * 31,
        '1Laura',
        'Laura_G',
        'Laaaura',
        'Laura  Gomez',
      ]) {
        expect(RegisterRules.nameProblem(name), isNotNull, reason: name);
      }
    });
  });

  group('email', () {
    test('accepts the providers of the backend, ignoring case', () {
      expect(RegisterRules.emailProblem('laura@uniandes.edu.co'), isNull);
      expect(RegisterRules.emailProblem(' Laura@Gmail.com '), isNull);
    });

    test('rejects other providers and broken emails', () {
      expect(
        RegisterRules.emailProblem('laura@parkwise.test'),
        contains('Uniandes'),
      );
      expect(RegisterRules.emailProblem('laura'), 'Enter a valid email');
    });
  });

  group('password', () {
    test('accepts 8 to 64 characters with every kind of character', () {
      expect(RegisterRules.passwordProblem('Secret12!'), isNull);
    });

    test('says what is missing', () {
      expect(RegisterRules.passwordProblem('Se12!'), 'At least 8 characters');
      expect(
        RegisterRules.passwordProblem('Se12!${'a' * 60}'),
        'Up to 64 characters',
      );
      expect(RegisterRules.passwordProblem('Secret 12!'), 'No spaces');
      expect(
        RegisterRules.passwordProblem('secret12!'),
        'Add an uppercase letter',
      );
      expect(
        RegisterRules.passwordProblem('SECRET12!'),
        'Add a lowercase letter',
      );
      expect(RegisterRules.passwordProblem('Secret!!!'), 'Add a number');
      expect(
        RegisterRules.passwordProblem('Secret123'),
        'Add a symbol, like ! or #',
      );
    });
  });
}
