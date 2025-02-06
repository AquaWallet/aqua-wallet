import 'dart:async';

import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockSendAssetInputStateNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetInputState,
    SendAssetArguments> with Mock implements SendAssetInputStateNotifier {
  MockSendAssetInputStateNotifier({required this.input});

  final SendAssetInputState input;

  @override
  FutureOr<SendAssetInputState> build(SendAssetArguments arg) => input;
}
