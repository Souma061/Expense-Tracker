class AppConfig {
  /// API base URL (no trailing slash).
  ///
  /// Configure via `--dart-define=API_BASE_URL=...`.
  ///
  /// Common values:
  /// - Android Emulator: `http://10.0.2.2:8080/api/v1`
  /// - Physical device (same Wi-Fi): `http://<your-pc-ip>:8080/api/v1`
  ///   (start backend with `php spark serve --host 0.0.0.0 --port 8080`)
  /// - Production: `https://api.yourdomain.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'https://osss.in/expense_app/server/public/index.php/api/v1',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );
}
