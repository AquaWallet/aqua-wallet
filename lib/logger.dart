import 'package:logger/logger.dart';

class AnyModeFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

CustomLogger logger = CustomLogger();

class CustomLogger {
  factory CustomLogger() {
    return _customLogger;
  }

  CustomLogger._internal();

  static final CustomLogger _customLogger = CustomLogger._internal();

  static const String appName = 'Aqua';

  Logger internalLogger = Logger(
    printer: SimplePrinter(printTime: true),
    output: ConsoleOutput(),
  );

  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.t('$appName: $message',
        error: error, stackTrace: stackTrace);
  }

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.d('$appName: $message',
        error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.i('$appName: $message',
        error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.w('$appName: $message',
        error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.e('$appName: $message',
        error: error, stackTrace: stackTrace);
  }

  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.f('$appName: $message',
        error: error, stackTrace: stackTrace);
  }
}

class ConsoleOutput extends LogOutput {
  void printWrapped(Object object) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches('$object').forEach((match) async {
      final line = '${DateTime.now().millisecondsSinceEpoch} ${match.group(0)}';
      // ignore: avoid_print
      print(line);
    });
  }

  @override
  void output(OutputEvent event) {
    event.lines.forEach(printWrapped);
  }
}
