import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for managing application version information
class AppVersion {
  static late PackageInfo _packageInfo;
  static bool _initialized = false;

  /// Initialize the app version information
  static Future<void> init() async {
    if (!_initialized) {
      _packageInfo = await PackageInfo.fromPlatform();
      _initialized = true;
    }
  }

  /// Get the app's version string (e.g., "1.0.0")
  static String get version {
    _checkInitialized();
    return _packageInfo.version;
  }

  /// Get the app's build number (e.g., "1")
  static String get buildNumber {
    _checkInitialized();
    return _packageInfo.buildNumber;
  }

  /// Get the full version string with build number (e.g., "1.0.0 (1)")
  static String get fullVersion {
    _checkInitialized();
    return '${_packageInfo.version} (${_packageInfo.buildNumber})';
  }

  /// Get the app name
  static String get appName {
    _checkInitialized();
    return _packageInfo.appName;
  }

  /// Get the package name
  static String get packageName {
    _checkInitialized();
    return _packageInfo.packageName;
  }

  /// Check if the version utility has been initialized
  static void _checkInitialized() {
    if (!_initialized) {
      throw StateError('AppVersion has not been initialized. Call AppVersion.init() first.');
    }
  }
} 