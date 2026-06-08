import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
  static final _logger = Logger(
    level: kDebugMode ? Level.all : Level.off,
    printer: PrettyPrinter(
      methodCount: 0, // No method info
      errorMethodCount: 5, // Show method info for errors
      lineLength: 80, // Wrap lines at 80 characters
      colors: true, // Colorize output
      printEmojis: true, // Print emojis
      dateTimeFormat: DateTimeFormat.dateAndTime, // Print time
    ),
  );

  static void info(String message) => _logger.i(message);

  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  static void warning(String message) => _logger.w(message);

  static void debug(String message) => _logger.d(message);
}
