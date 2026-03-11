import 'package:aqua/features/sideswap/swap.dart';
import 'package:mocktail/mocktail.dart';

class MockPegStatusNotifier extends Mock {
  PegStatusState build() => const PegStatusState();

  Future<void> requestPegStatus({
    required String orderId,
    required bool isPegIn,
  }) async {}
}

extension MockPegStatusNotifierX on MockPegStatusNotifier {
  void mockPegStatus(PegStatusState status) {
    when(() => build()).thenReturn(status);
  }

  void mockRequestPegStatus() {
    when(() => requestPegStatus(
          orderId: any(named: 'orderId'),
          isPegIn: any(named: 'isPegIn'),
        )).thenAnswer((_) async {});
  }
}
