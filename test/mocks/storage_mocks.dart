import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:mocktail/mocktail.dart';

class MockEncryption extends Mock implements Encryption {}

class MockSecureStorageProvider extends Mock implements IStorage {}

class MockFileSystemProvider extends Mock implements DeviceIO {}

class MockTransactionStorageProvider
    extends AsyncNotifier<List<TransactionDbModel>>
    with Mock
    implements TransactionStorageNotifier {
  @override
  FutureOr<List<TransactionDbModel>> build() async => kMockDbTransactions;

  @override
  Future<void> save(TransactionDbModel model) async => Future.value(null);
}

class MockSideshiftStorageProvider
    extends AsyncNotifier<List<SideshiftOrderDbModel>>
    with Mock
    implements SideshiftOrderStorageNotifier {
  @override
  FutureOr<List<SideshiftOrderDbModel>> build() async => kMockDbSideshiftOrders;
}

class MockBoltzStorageProvider extends AsyncNotifier<List<BoltzSwapDbModel>>
    with Mock
    implements BoltzSwapStorageNotifier {
  @override
  FutureOr<List<BoltzSwapDbModel>> build() async => kMockDbBoltzSwaps;
}
