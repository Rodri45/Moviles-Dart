abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://parkwise-api-a1f0.onrender.com',
  );

  static const String prefix = '/api/v1';

  static const Duration timeout = Duration(seconds: 4);
}
