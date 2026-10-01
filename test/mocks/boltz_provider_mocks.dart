import 'package:aqua/features/boltz/boltz.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockLbtcLnSwap extends Mock implements LbtcLnSwap {}

class MockBoltzSubmarineSwapNotifier extends StateNotifier<LbtcLnSwap?>
    with Mock
    implements BoltzSubmarineSwapNotifier {
  MockBoltzSubmarineSwapNotifier({LbtcLnSwap? swap}) : super(swap);
}

class MockBoltzSubmarineFeesNotifier
    extends AutoDisposeAsyncNotifier<SubmarineFeesAndLimits>
    with Mock
    implements BoltzSubmarineFeesNotifier {
  MockBoltzSubmarineFeesNotifier(this.fees);

  final SubmarineFeesAndLimits fees;

  @override
  Future<SubmarineFeesAndLimits> build() async => fees;
}
