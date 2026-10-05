/// Settings that can be changed WITHOUT editing code.
/// PUBLIC_BASE_URL is supplied at build time (see README, "Settings").
class AppConfig {
  static const publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://yourapp.example.com',
  );

  static bool get isPlaceholderUrl => publicBaseUrl.contains('example.com');
}
