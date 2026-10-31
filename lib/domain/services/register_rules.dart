abstract final class RegisterRules {
  static const nameMinLength = 2;
  static const nameMaxLength = 30;
  static const emailMaxLength = 100;
  static const passwordMinLength = 8;
  static const passwordMaxLength = 64;

  static const emailProviders = {
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'yahoo.com',
    'icloud.com',
    'me.com',
    'proton.me',
    'protonmail.com',
    'uniandes.edu.co',
  };

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _name = RegExp(r"^\p{L}[\p{L} '.-]*$", unicode: true);
  static final _sameLetterThreeTimes = RegExp(
    r'(\p{L})\1\1',
    unicode: true,
    caseSensitive: false,
  );
  static final _uppercase = RegExp(r'\p{Lu}', unicode: true);
  static final _lowercase = RegExp(r'\p{Ll}', unicode: true);
  static final _number = RegExp(r'\p{N}', unicode: true);
  static final _symbol = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final _space = RegExp(r'\s');

  static String? nameProblem(String value) {
    final name = value.trim();
    if (name.length < nameMinLength) {
      return 'The name needs at least $nameMinLength characters';
    }
    if (name.length > nameMaxLength) {
      return 'The name can have up to $nameMaxLength characters';
    }
    if (!_name.hasMatch(name)) {
      return 'Use only letters, spaces, apostrophes, dots and hyphens';
    }
    if (_sameLetterThreeTimes.hasMatch(name.replaceAll(' ', ''))) {
      return 'Don\'t repeat the same letter three times in a row';
    }
    if (name.contains('  ')) return 'Don\'t use double spaces';
    return null;
  }

  static String? emailProblem(String value) {
    final email = value.trim().toLowerCase();
    if (email.length > emailMaxLength || !_email.hasMatch(email)) {
      return 'Enter a valid email';
    }
    if (!emailProviders.contains(email.split('@').last)) {
      return 'Use Gmail, Outlook, Hotmail, Live, Yahoo, iCloud, Proton or '
          'your Uniandes email';
    }
    return null;
  }

  static String? passwordProblem(String password) {
    if (password.length < passwordMinLength) {
      return 'At least $passwordMinLength characters';
    }
    if (password.length > passwordMaxLength) {
      return 'Up to $passwordMaxLength characters';
    }
    if (_space.hasMatch(password)) return 'No spaces';
    if (!_uppercase.hasMatch(password)) return 'Add an uppercase letter';
    if (!_lowercase.hasMatch(password)) return 'Add a lowercase letter';
    if (!_number.hasMatch(password)) return 'Add a number';
    if (!_symbol.hasMatch(password)) return 'Add a symbol, like ! or #';
    return null;
  }
}
