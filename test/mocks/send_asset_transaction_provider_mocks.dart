import 'dart:async';

import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockSendAssetTxnProvider extends AutoDisposeFamilyAsyncNotifier<
    SendAssetTransactionState,
    SendAssetArguments> with Mock implements SendAssetTxnNotifier {
  MockSendAssetTxnProvider({required this.transaction});

  final SendAssetOnchainTx? transaction;

  @override
  FutureOr<SendAssetTransactionState> build(SendAssetArguments arg) =>
      transaction != null
          ? SendAssetTransactionState.created(tx: transaction!)
          : const SendAssetTransactionState.idle();
}
