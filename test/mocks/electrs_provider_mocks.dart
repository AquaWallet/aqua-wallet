import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

class MockElectrsClient extends Mock implements ElectrsClient {}

extension MockElectrsClientX on MockElectrsClient {
  void mockBroadcast({
    required String txId,
    NetworkType network = NetworkType.liquid,
  }) {
    when(() => broadcast(any(), network)).thenAnswer((_) async => txId);
  }
}
