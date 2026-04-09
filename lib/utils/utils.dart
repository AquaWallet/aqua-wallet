import 'dart:async';

import 'package:flutter/foundation.dart';

export 'extensions/extensions.dart';
export 'fake_data.dart';
export 'regex.dart';
export 'responsive_utils.dart';
export 'zendesk.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttler {
  final int milliseconds;
  Timer? _timer;
  bool _isThrottled = false;

  Throttler({required this.milliseconds});

  void run(VoidCallback action) {
    if (!_isThrottled) {
      action();
      _isThrottled = true;
      _timer = Timer(Duration(milliseconds: milliseconds), () {
        _isThrottled = false;
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

Future<T?> retryAsync<T>(
  Future<T?> Function() operation,
  bool Function(T?) successCondition,
  int maxRetries,
  Duration delay,
) async {
  for (int i = 0; i <= maxRetries; i++) {
    final result = await operation();
    if (successCondition(result)) {
      return result;
    }
    if (i < maxRetries) {
      await Future.delayed(delay);
    }
  }
  return null; // Indicate failure after max retries
}
