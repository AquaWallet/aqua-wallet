import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:mocktail/mocktail.dart';

class MockPegNotifier extends AutoDisposeAsyncNotifier<PegState>
    with Mock
    implements PegNotifier {
  MockPegNotifier(this.pegState);

  final PegState pegState;

  @override
  FutureOr<PegState> build() => pegState;
}
