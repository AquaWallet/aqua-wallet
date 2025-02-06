import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:mocktail/mocktail.dart';

class MockSideswapInputStateNotifier extends StateNotifier<SideswapInputState>
    with Mock
    implements SideswapInputStateNotifier {
  final SideswapInputState input;

  MockSideswapInputStateNotifier(this.input) : super(input);
}

extension MockSideswapInputStateNotifierX on MockSideswapInputStateNotifier {
  void mockIsPegIn({bool value = true}) {
    when(() => state.isPegIn).thenReturn(value);
  }
}
