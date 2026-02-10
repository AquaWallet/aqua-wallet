import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockEncryption extends Mock implements Encryption {}

class MockSecureStorageProvider extends Mock implements IStorage {}

class MockFileSystemProvider extends Mock implements DeviceIO {}

class MockTransactionStorageProvider
    extends AsyncNotifier<List<TransactionDbModel>>
    with Mock
    implements TransactionStorageNotifier {
  MockTransactionStorageProvider({List<TransactionDbModel>? transactions})
      : _transactions = transactions;

  final List<TransactionDbModel>? _transactions;

  @override
  FutureOr<List<TransactionDbModel>> build() async =>
      _transactions ?? kMockDbTransactions;

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
  MockBoltzStorageProvider({List<BoltzSwapDbModel>? swaps}) : _swaps = swaps;

  final List<BoltzSwapDbModel>? _swaps;

  @override
  FutureOr<List<BoltzSwapDbModel>> build() async => _swaps ?? kMockDbBoltzSwaps;
}

class MockPegStorageNotifier extends AsyncNotifier<List<PegOrderDbModel>>
    with Mock
    implements PegOrderStorageNotifier {
  MockPegStorageNotifier({List<PegOrderDbModel>? orders}) : _orders = orders;

  final List<PegOrderDbModel>? _orders;

  @override
  FutureOr<List<PegOrderDbModel>> build() async => _orders ?? [];

  @override
  Future<PegOrderDbModel?> getOrderById(String orderId) async {
    return (_orders ?? []).cast<PegOrderDbModel?>().firstWhere(
          (order) => order?.orderId == orderId,
          orElse: () => null,
        );
  }

  @override
  Future<List<PegOrderDbModel>> getAllPegOrders() async {
    return _orders ?? [];
  }

  @override
  Future<List<PegOrderDbModel>> getAllPendingSettlementPegOrders() async {
    // Filter orders by isPendingSettlement, matching real implementation behavior
    return (_orders ?? []).where((order) {
      final consolidatedStatus = order.status.getConsolidatedStatus();
      return PegStatusState(consolidatedStatus: consolidatedStatus)
          .isPendingSettlement;
    }).toList();
  }
}
