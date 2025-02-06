import 'dart:async';

import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockSendAssetFeeNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetFeeState,
    SendAssetArguments> with Mock implements SendAssetFeeNotifier {
  MockSendAssetFeeNotifier(this.feeState);

  final SendAssetFeeState feeState;

  @override
  FutureOr<SendAssetFeeState> build(SendAssetArguments arg) async {
    return feeState;
  }
}
