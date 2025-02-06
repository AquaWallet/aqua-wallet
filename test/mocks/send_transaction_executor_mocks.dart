import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:mocktail/mocktail.dart';

class MockSendGdkTransactor extends Mock implements Transactor {}

extension MockSendGdkTransactorX on MockSendGdkTransactor {
  void mockCreateTransaction(
    SendAssetOnchainTx? res,
  ) {
    when(() => createTransaction(
          sendInput: any(named: 'sendInput'),
          rbfEnabled: any(named: 'rbfEnabled'),
        )).thenAnswer((_) => Future.value(res));
  }

  void mockSignTransaction(GdkNewTransactionReply transaction) {
    when(
      () => signTransaction(
        transaction: any(named: 'transaction'),
        network: any(named: 'network'),
      ),
    ).thenAnswer((_) => Future.value(transaction));
  }

  void mockBroadcastTransaction(String rawTx) {
    when(() => broadcastTransaction(
          rawTx: any(named: 'rawTx'),
          network: any(named: 'network'),
        )).thenAnswer((_) => Future.value(rawTx));
  }
}
