import 'dart:async';

import 'package:aqua/features/swaps/swaps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferredUsdtServiceNotifier extends AsyncNotifier<SwapServiceSource>
    with Mock
    implements PreferredUsdtServiceNotifier {
  MockPreferredUsdtServiceNotifier(this._serviceSource);

  final SwapServiceSource? _serviceSource;

  @override
  Future<SwapServiceSource> build() async {
    if (_serviceSource == null) {
      throw StateError('No swap service selected');
    }
    return _serviceSource;
  }
}
