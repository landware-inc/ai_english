// lib/utils/logger.dart

class Logger {
  static bool _enableDebug = true;

  // Set debug mode (can be toggled in settings)
  static void setDebugMode(bool isEnabled) {
    _enableDebug = isEnabled;
  }

  // Debug level logging - only shown when debug mode is enabled
  static void debug(String message) {
    if (_enableDebug) {
      _log('DEBUG', message);
    }
  }

  // Info level logging - always shown
  static void info(String message) {
    _log('INFO', message);
  }

  // Warning level logging - always shown
  static void warning(String message) {
    _log('WARNING', message);
  }

  // Error level logging - always shown
  static void error(String message) {
    _log('ERROR', message);
  }

  // Internal logging method
  static void _log(String level, String message) {
    final timestamp = DateTime.now().toString();
    print('[$level] $timestamp - $message');

    // In a production app, you might want to save logs to a file
    // or send them to a monitoring service
  }
}