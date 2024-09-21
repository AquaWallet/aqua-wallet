import 'dart:async';

import 'package:flutter/foundation.dart';

export 'extensions/extensions.dart';
export 'fake_data.dart';
export 'responsive_utils.dart';

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
}
