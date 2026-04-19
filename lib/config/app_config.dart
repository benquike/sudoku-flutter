// lib/config/app_config.dart
class AppConfig {
  final bool enableGoogleFirebase;
  final String hivePackageName;

  AppConfig({
    required this.enableGoogleFirebase,
    required this.hivePackageName,
  });

  // Factory constructor for different environments (e.g., dev, prod)
  factory AppConfig.forEnvironment() {
    // Default to production values
    return AppConfig(
      enableGoogleFirebase: true,
      hivePackageName: "com.sevlow.app.sudoku",
    );
  }
}
