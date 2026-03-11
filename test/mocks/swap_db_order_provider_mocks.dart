import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/swaps/swaps.dart';

class MockSwapDBOrderNotifier extends SwapDBOrderNotifier {
  final SwapOrderDbModel? Function(String)? mockBuilder;

  MockSwapDBOrderNotifier({this.mockBuilder});

  @override
  FutureOr<SwapOrderDbModel?> build(String arg) async {
    return mockBuilder?.call(arg);
  }
}
