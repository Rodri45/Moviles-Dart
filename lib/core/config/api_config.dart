// la url del backend se pasa con --dart-define=API_BASE_URL=...
// sin eso queda el backend local visto desde el emulador de android
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String prefix = '/api/v1';

  static const Duration timeout = Duration(seconds: 4);
}
