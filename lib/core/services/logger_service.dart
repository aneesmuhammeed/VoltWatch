import 'dart:io';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, warning, error }

class LoggerService {
  static final LoggerService _instance = LoggerService._();
  static LoggerService get instance => _instance;
  LoggerService._();

  bool _enabled = true;

  void enable() => _enabled = true;
  void disable() => _enabled = false;

  void _log(LogLevel level, String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_enabled) return;
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final levelStr = level.name.toUpperCase().padRight(7);
    final buffer = StringBuffer('[$timestamp] [$levelStr] [$tag] $message');
    if (error != null) {
      buffer.write(' | Error: $error');
    }
    if (stackTrace != null) {
      buffer.write(' | StackTrace: $stackTrace');
    }
    final supportsAnsi = !Platform.isAndroid && !Platform.isIOS;
    String colorCode = '\x1B[0m'; // Default reset
    if (supportsAnsi) {
      switch (level) {
        case LogLevel.debug:
          colorCode = '\x1B[32m'; // Green
          break;
        case LogLevel.info:
          colorCode = '\x1B[34m'; // Blue
          break;
        case LogLevel.warning:
          colorCode = '\x1B[33m'; // Yellow
          break;
        case LogLevel.error:
          colorCode = '\x1B[31m'; // Red
          break;
      }
    }

    // ignore: avoid_print
    print('$colorCode${buffer.toString()}${supportsAnsi ? '\x1B[0m' : ''}');
  }

  void debug(String tag, String message) => _log(LogLevel.debug, tag, message);
  void info(String tag, String message) => _log(LogLevel.info, tag, message);
  void warning(String tag, String message, [dynamic error]) => _log(LogLevel.warning, tag, message, error);
  void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) => _log(LogLevel.error, tag, message, error, stackTrace);
}
