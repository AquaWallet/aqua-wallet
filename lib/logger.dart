import 'package:logger/logger.dart' as log;
import 'package:logger/logger.dart';

class AnyModeFilter extends log.LogFilter {
  @override
  bool shouldLog(log.LogEvent event) {
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

  log.Logger internalLogger = log.Logger(
    printer: log.SimplePrinter(printTime: true),
    output: ConsoleOutput(),
  );

  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.v('$appName: $message', error, stackTrace);
  }

  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.d('$appName: $message', error, stackTrace);
  }

  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.i('$appName: $message', error, stackTrace);
  }

  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.w('$appName: $message', error, stackTrace);
  }

  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.e('$appName: $message', error, stackTrace);
  }

  void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    internalLogger.wtf('$appName: $message', error, stackTrace);
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
