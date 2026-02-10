import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:mocktail/mocktail.dart';

class MockPegSwapMatcher extends Mock implements PegSwapMatcher {
  void mockLookupPegSides({
    GdkTransaction? sendTxn,
    GdkTransaction? receiveTxn,
  }) {
    when(() => lookupPegSides(
          pegOrder: any(named: 'pegOrder'),
          sendNetworkTxns: any(named: 'sendNetworkTxns'),
          receiveNetworkTxns: any(named: 'receiveNetworkTxns'),
        )).thenReturn((sendTxn: sendTxn, receiveTxn: receiveTxn));
  }
}
