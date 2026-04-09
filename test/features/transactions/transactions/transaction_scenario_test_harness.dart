import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:boltz/boltz.dart' as boltz;
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks/mocks.dart';

/// Sets up default stubs on a [MockConfirmationService] that mirror the real
/// [ConfirmationService] behavior, including ghost/boltz transaction pending
/// logic and the staleness check against network transactions.
///
/// Individual tests can still override `getConfirmationCount` or
/// `getRequiredConfirmationCount` to control whether transactions appear
/// confirmed. The `isGhostTransactionPending` stub delegates to those methods
/// automatically.
void setupConfirmationServiceDefaults(MockConfirmationService mock) {
  when(() => mock.getConfirmationCount(any(), any()))
      .thenAnswer((_) async => 0);
  when(() => mock.getRequiredConfirmationCount(any())).thenReturn(1);
  when(() => mock.isTransactionPending(
        asset: any(named: 'asset'),
        transaction: any(named: 'transaction'),
        dbTransaction: any(named: 'dbTransaction'),
      )).thenAnswer((_) async => false);
  when(() => mock.isGhostTransactionPending(
        ghostTxn: any(named: 'ghostTxn'),
        asset: any(named: 'asset'),
        networkTxns: any(named: 'networkTxns'),
      )).thenAnswer((invocation) async {
    final ghostTxn = invocation.namedArguments[#ghostTxn] as TransactionDbModel;
    final asset = invocation.namedArguments[#asset] as Asset;
    final networkTxns =
        invocation.namedArguments[#networkTxns] as List<GdkTransaction>;

    final matchingNetworkTxn = networkTxns
        .cast<GdkTransaction?>()
        .firstWhere((t) => t!.txhash == ghostTxn.txhash, orElse: () => null);

    if (matchingNetworkTxn == null && networkTxns.isNotEmpty) {
      final ghostCreatedAt = ghostTxn.ghostTxnCreatedAt?.microsecondsSinceEpoch;
      final lastNetworkCreatedAt = networkTxns.last.createdAtTs;
      if (lastNetworkCreatedAt == null || ghostCreatedAt == null) {
        return false;
      }
      if (ghostCreatedAt < lastNetworkCreatedAt) {
        return false;
      }
    }

    final confirmationCount = await mock.getConfirmationCount(
      asset,
      matchingNetworkTxn?.blockHeight ?? 0,
    );
    final requiredConfirmations = mock.getRequiredConfirmationCount(asset);

    return confirmationCount < requiredConfirmations;
  });
}

/// A test harness for simulating realistic transaction scenarios
///
/// Usage:
/// ```dart
/// final scenario = TransactionScenarioHarness()
///   .withBtcIncoming(amount: 100000000, confirmations: 0)  // Pending
///   .withLbtcSwapToUsdt(lbtcAmount: 50000000, usdtAmount: 10000000)
///   .build();
///
/// final container = scenario.createContainer(
///   formatService: mockFormatService,
///   txnFailureService: mockTxnFailureService,
/// );
///
/// final btcTxns = await container.read(transactionsProvider(Asset.btc()).future);
/// expect(btcTxns.first, isA<PendingTransactionUiModel>());
/// ```
class TransactionScenarioHarness {
  final List<TransactionScenario> _scenarios = [];
  final Map<String, Asset> _assets = {};
  int _txCounter = 0;
  final DateTime _baseTime = DateTime.now();

  TransactionScenarioHarness() {
    // Register common assets
    _assets['btc'] = Asset.btc();
    _assets['lbtc'] = Asset.lbtc();
    _assets['usdt'] = Asset.usdtLiquid();
    _assets['lightning'] = Asset.lightning();
    // Register alt USDt assets for swap testing
    _assets['usdtEth'] = Asset.usdtEth();
    _assets['usdtTrx'] = Asset.usdtTrx();
    _assets['usdtBep'] = Asset.usdtBep();
    _assets['usdtSol'] = Asset.usdtSol();
    _assets['usdtPol'] = Asset.usdtPol();
    _assets['usdtTon'] = Asset.usdtTon();
  }

  /// Add a BTC incoming transaction
  TransactionScenarioHarness withBtcIncoming({
    required int amount,
    int confirmations = 6,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: _assets['btc']!,
      type: GdkTransactionTypeEnum.incoming,
      amount: amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'btc_in_${_txCounter++}',
    ));
    return this;
  }

  /// Add a BTC outgoing transaction
  TransactionScenarioHarness withBtcOutgoing({
    required int amount,
    int confirmations = 6,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: _assets['btc']!,
      type: GdkTransactionTypeEnum.outgoing,
      amount: -amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'btc_out_${_txCounter++}',
    ));
    return this;
  }

  /// Add an L-BTC incoming transaction
  TransactionScenarioHarness withLbtcIncoming({
    required int amount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.incoming,
      amount: amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'lbtc_in_${_txCounter++}',
    ));
    return this;
  }

  /// Add an L-BTC outgoing transaction
  TransactionScenarioHarness withLbtcOutgoing({
    required int amount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.outgoing,
      amount: -amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'lbtc_out_${_txCounter++}',
    ));
    return this;
  }

  /// Add a USDt incoming transaction
  TransactionScenarioHarness withUsdtIncoming({
    required int amount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: _assets['usdt']!,
      type: GdkTransactionTypeEnum.incoming,
      amount: amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'usdt_in_${_txCounter++}',
    ));
    return this;
  }

  /// Add a USDt outgoing transaction (send)
  /// For pending transactions, also creates a database entry (ghost transaction)
  TransactionScenarioHarness withUsdtOutgoing({
    required int amount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
    bool createDbEntry =
        false, // Set to true to create database entry for pending tracking
  }) {
    final hash = txhash ?? 'usdt_out_${_txCounter++}';
    final time = timestamp ?? _baseTime.subtract(Duration(hours: _txCounter));

    // Network transaction (outgoing)
    _scenarios.add(TransactionScenario(
      asset: _assets['usdt']!,
      type: GdkTransactionTypeEnum.outgoing,
      amount: -amount,
      confirmations: confirmations,
      timestamp: time,
      txhash: hash,
    ));

    // Database entry (for pending transaction tracking)
    if (createDbEntry) {
      _scenarios.add(TransactionScenario(
        asset: _assets['usdt']!,
        type: GdkTransactionTypeEnum.outgoing,
        amount: -amount,
        confirmations: confirmations,
        timestamp: time,
        txhash: hash,
        isGhost: true,
        ghostType: TransactionDbModelType.aquaSend,
      ));
    }

    return this;
  }

  /// Add an L-BTC to USDt swap transaction
  /// This creates transactions on BOTH asset sides
  TransactionScenarioHarness withLbtcSwapToUsdt({
    required int lbtcAmount,
    required int usdtAmount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    final hash = txhash ?? 'swap_lbtc_usdt_${_txCounter++}';
    final time = timestamp ?? _baseTime.subtract(Duration(hours: _txCounter));

    // L-BTC side (outgoing)
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.swap,
      amount: -lbtcAmount,
      confirmations: confirmations,
      timestamp: time,
      txhash: hash,
      swapOutgoingAssetId: _assets['lbtc']!.id,
      swapIncomingAssetId: _assets['usdt']!.id,
      swapOutgoingAmount: lbtcAmount,
      swapIncomingAmount: usdtAmount,
    ));

    // USDt side (incoming)
    _scenarios.add(TransactionScenario(
      asset: _assets['usdt']!,
      type: GdkTransactionTypeEnum.swap,
      amount: usdtAmount,
      confirmations: confirmations,
      timestamp: time,
      txhash: hash,
      swapOutgoingAssetId: _assets['lbtc']!.id,
      swapIncomingAssetId: _assets['usdt']!.id,
      swapOutgoingAmount: lbtcAmount,
      swapIncomingAmount: usdtAmount,
    ));

    return this;
  }

  /// Add a USDt to L-BTC swap transaction
  /// This creates transactions on BOTH asset sides
  TransactionScenarioHarness withUsdtSwapToLbtc({
    required int usdtAmount,
    required int lbtcAmount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    final hash = txhash ?? 'swap_usdt_lbtc_${_txCounter++}';
    final time = timestamp ?? _baseTime.subtract(Duration(hours: _txCounter));

    // USDt side (outgoing)
    _scenarios.add(TransactionScenario(
      asset: _assets['usdt']!,
      type: GdkTransactionTypeEnum.swap,
      amount: -usdtAmount,
      confirmations: confirmations,
      timestamp: time,
      txhash: hash,
      swapOutgoingAssetId: _assets['usdt']!.id,
      swapIncomingAssetId: _assets['lbtc']!.id,
      swapOutgoingAmount: usdtAmount,
      swapIncomingAmount: lbtcAmount,
    ));

    // L-BTC side (incoming)
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.swap,
      amount: lbtcAmount,
      confirmations: confirmations,
      timestamp: time,
      txhash: hash,
      swapOutgoingAssetId: _assets['usdt']!.id,
      swapIncomingAssetId: _assets['lbtc']!.id,
      swapOutgoingAmount: usdtAmount,
      swapIncomingAmount: lbtcAmount,
    ));

    return this;
  }

  /// Add a ghost (pending) transaction
  TransactionScenarioHarness withGhostTransaction({
    required Asset asset,
    required int amount,
    TransactionDbModelType type = TransactionDbModelType.aquaSend,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: asset,
      type: GdkTransactionTypeEnum.outgoing,
      amount: amount,
      confirmations: 0,
      timestamp: timestamp ?? _baseTime.subtract(const Duration(minutes: 5)),
      txhash: txhash ?? 'ghost_${_txCounter++}',
      isGhost: true,
      ghostType: type,
    ));
    return this;
  }

  /// Add a peg transaction (BTC <-> L-BTC)
  TransactionScenarioHarness withPegTransaction({
    required bool isPegIn,
    required int amount,
    int confirmations = 0,
    int detectedConfs = 0,
    DateTime? timestamp,
    String? txhash,
    String? orderId,
  }) {
    final asset = isPegIn ? _assets['lbtc']! : _assets['btc']!;
    final hash = txhash ?? 'peg_${_txCounter++}';
    final id = orderId ?? 'peg_order_$_txCounter';

    // For peg-out, BTC is being received (incoming)
    // For peg-in, L-BTC is being received (incoming)
    final type = isPegIn
        ? GdkTransactionTypeEnum.incoming // L-BTC incoming
        : GdkTransactionTypeEnum.incoming; // BTC incoming (for peg-out)

    _scenarios.add(TransactionScenario(
      asset: asset,
      type: type,
      amount: amount, // Always positive for incoming transactions
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(const Duration(minutes: 10)),
      txhash: hash,
      isPeg: true,
      pegOrderId: id,
      pegDetectedConfs: detectedConfs,
    ));

    return this;
  }

  /// Add a direct peg-in transaction (BTC -> L-BTC via deposit address)
  ///
  /// Direct peg-ins have different txhashes on BTC and L-BTC sides:
  /// - BTC deposit has its own txhash (stored in peg order)
  /// - L-BTC receive has a different txhash (what GDK sees)
  /// - They're linked by the receiveAddress
  TransactionScenarioHarness withDirectPegInTransaction({
    required int amount,
    int confirmations = 2,
    int detectedConfs = 0,
    DateTime? timestamp,
    String? lbtcTxhash,
    String? orderId,
    String? receiveAddress,
    bool isPending = false,
  }) {
    final lbtcHash = lbtcTxhash ?? 'lbtc_peg_in_${_txCounter++}';
    final id = orderId ?? 'direct_peg_order_$_txCounter';
    final recvAddr = receiveAddress ?? 'lq1receive_$_txCounter';

    // L-BTC incoming transaction (what we see in the wallet)
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.incoming,
      amount: amount,
      confirmations: isPending ? 0 : confirmations,
      timestamp: timestamp ?? _baseTime.subtract(const Duration(minutes: 10)),
      txhash: lbtcHash,
      isPeg: true,
      pegOrderId: id,
      pegDetectedConfs: detectedConfs,
      pegReceiveAddress: recvAddr,
    ));

    return this;
  }

  /// Add a Lightning transaction with Boltz order
  TransactionScenarioHarness withLightningTransaction({
    required int amount,
    required bool isIncoming,
    int confirmations = 1,
    String? boltzOrderId,
    String? claimTxId,
    DateTime? timestamp,
  }) {
    final hash = claimTxId ?? 'ln_claim_${_txCounter++}';
    final orderId = boltzOrderId ?? 'boltz_order_$_txCounter';

    _scenarios.add(TransactionScenario(
      asset: _assets['lightning']!,
      type: isIncoming
          ? GdkTransactionTypeEnum.incoming
          : GdkTransactionTypeEnum.outgoing,
      amount: isIncoming ? amount : -amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(const Duration(minutes: 3)),
      txhash: hash,
      isBoltz: true,
      boltzOrderId: orderId,
      boltzClaimTxId: hash,
    ));

    return this;
  }

  // Add a failed Lightning send transaction with refund
  //
  // Creates two transactions that share the same serviceOrderId:
  // 1. Failed send transaction (boltzSendFailed)
  // 2. Refund transaction (boltzRefund)
  TransactionScenarioHarness withFailedLightningTransaction({
    required int sendAmount,
    required int refundAmount,
    String? boltzOrderId,
    String? failedTxHash,
    String? refundTxHash,
    DateTime? timestamp,
    int refundConfirmations = 2,
  }) {
    final orderId = boltzOrderId ?? 'boltz_failed_$_txCounter';
    final failedHash = failedTxHash ?? 'failed_send_${_txCounter++}';
    final refundHash = refundTxHash ?? 'refund_${_txCounter++}';
    final time = timestamp ?? _baseTime.subtract(const Duration(minutes: 10));

    // Failed send transaction
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.outgoing,
      amount: -sendAmount,
      confirmations: 0, // Failed transactions are typically unconfirmed
      timestamp: time,
      txhash: failedHash,
      isGhost: true,
      ghostType: TransactionDbModelType.boltzSendFailed,
      isBoltz: true,
      boltzOrderId: orderId,
    ));

    // Refund transaction
    _scenarios.add(TransactionScenario(
      asset: _assets['lbtc']!,
      type: GdkTransactionTypeEnum.incoming,
      amount: refundAmount,
      confirmations: refundConfirmations,
      timestamp: time.add(const Duration(minutes: 5)),
      txhash: refundHash,
      isGhost: true,
      ghostType: TransactionDbModelType.boltzRefund,
      isBoltz: true,
      boltzOrderId: orderId, // Same serviceOrderId as failed send
    ));

    return this;
  }

  /// Add a redeposit transaction
  TransactionScenarioHarness withRedeposit({
    required Asset asset,
    required int amount,
    int confirmations = 2,
    DateTime? timestamp,
    String? txhash,
  }) {
    _scenarios.add(TransactionScenario(
      asset: asset,
      type: GdkTransactionTypeEnum.redeposit,
      amount: amount,
      confirmations: confirmations,
      timestamp: timestamp ?? _baseTime.subtract(Duration(hours: _txCounter)),
      txhash: txhash ?? 'redeposit_${_txCounter++}',
    ));
    return this;
  }

  /// Add a Sideshift swap transaction (USDt swaps)
  /// Creates a swap order in swapStorageProvider
  TransactionScenarioHarness withSideshiftSwap({
    required Asset fromAsset,
    required Asset toAsset,
    required int fromAmount,
    int? toAmount,
    String? orderId,
    SwapOrderStatus status = SwapOrderStatus.processing,
    DateTime? timestamp,
    String? txhash,
  }) {
    final hash = txhash ?? 'sideshift_swap_${_txCounter++}';
    final id = orderId ?? 'sideshift_order_$_txCounter';
    final time = timestamp ?? _baseTime.subtract(Duration(hours: _txCounter));
    final settleAmount = toAmount ?? (fromAmount * 95 ~/ 100); // Rough estimate

    // Create scenario for the receiving side (toAsset)
    _scenarios.add(TransactionScenario(
      asset: toAsset,
      type: GdkTransactionTypeEnum.incoming,
      amount: settleAmount,
      confirmations: 0, // Pending swap
      timestamp: time,
      txhash: hash,
      isGhost: true,
      ghostType: TransactionDbModelType.sideshiftSwap,
      isSwapOrder: true,
      swapServiceSource: SwapServiceSource.sideshift,
      swapOrderId: id,
      swapFromAsset: fromAsset,
      swapToAsset: toAsset,
      swapOrderStatus: status,
      swapDepositAmount: fromAmount,
    ));

    return this;
  }

  /// Add a Changelly swap transaction (USDt swaps)
  /// Creates a swap order in swapStorageProvider
  TransactionScenarioHarness withChangellySwap({
    required Asset fromAsset,
    required Asset toAsset,
    required int fromAmount,
    int? toAmount,
    String? orderId,
    SwapOrderStatus status = SwapOrderStatus.processing,
    DateTime? timestamp,
    String? txhash,
  }) {
    final hash = txhash ?? 'changelly_swap_${_txCounter++}';
    final id = orderId ?? 'changelly_order_$_txCounter';
    final time = timestamp ?? _baseTime.subtract(Duration(hours: _txCounter));
    final settleAmount = toAmount ?? (fromAmount * 95 ~/ 100); // Rough estimate

    // Create scenario for the receiving side (toAsset)
    _scenarios.add(TransactionScenario(
      asset: toAsset,
      type: GdkTransactionTypeEnum.incoming,
      amount: settleAmount,
      confirmations: 0, // Pending swap
      timestamp: time,
      txhash: hash,
      isGhost: true,
      ghostType: TransactionDbModelType.sideshiftSwap,
      isSwapOrder: true,
      swapServiceSource: SwapServiceSource.changelly,
      swapOrderId: id,
      swapFromAsset: fromAsset,
      swapToAsset: toAsset,
      swapOrderStatus: status,
      swapDepositAmount: fromAmount,
    ));

    return this;
  }

  /// Build the scenario and return a configured test environment
  ScenarioEnvironment build() {
    // Collect all unique assets from scenarios (including swap order assets)
    final allAssets = <Asset>{};

    // First, add all base assets
    allAssets.addAll(_assets.values);

    // Then, add assets from scenarios
    for (final scenario in _scenarios) {
      allAssets.add(scenario.asset);
      if (scenario.swapFromAsset != null) {
        allAssets.add(scenario.swapFromAsset!);
      }
      if (scenario.swapToAsset != null) {
        allAssets.add(scenario.swapToAsset!);
      }
    }

    // For swap transactions, explicitly ensure both swap assets are included
    // This is critical - swap transactions require both assets to be available
    for (final scenario in _scenarios) {
      if (scenario.type == GdkTransactionTypeEnum.swap) {
        // Ensure the incoming asset is included
        if (scenario.swapIncomingAssetId != null) {
          final incomingAsset = allAssets.firstWhereOrNull(
            (a) => a.id == scenario.swapIncomingAssetId,
          );
          if (incomingAsset == null) {
            // Try to find in _assets
            final fromAssets = _assets.values.firstWhereOrNull(
              (a) => a.id == scenario.swapIncomingAssetId,
            );
            if (fromAssets != null) {
              allAssets.add(fromAssets);
            }
          }
        }
        // Ensure the outgoing asset is included
        if (scenario.swapOutgoingAssetId != null) {
          final outgoingAsset = allAssets.firstWhereOrNull(
            (a) => a.id == scenario.swapOutgoingAssetId,
          );
          if (outgoingAsset == null) {
            // Try to find in _assets
            final fromAssets = _assets.values.firstWhereOrNull(
              (a) => a.id == scenario.swapOutgoingAssetId,
            );
            if (fromAssets != null) {
              allAssets.add(fromAssets);
            }
          }
        }
      }
    }

    return ScenarioEnvironment(_scenarios, allAssets.toList());
  }
}

/// Internal representation of a transaction scenario
class TransactionScenario {
  final Asset asset;
  final GdkTransactionTypeEnum type;
  final int amount;
  final int confirmations;
  final DateTime timestamp;
  final String txhash;
  final String? swapOutgoingAssetId;
  final String? swapIncomingAssetId;
  final int? swapOutgoingAmount;
  final int? swapIncomingAmount;
  final bool isGhost;
  final TransactionDbModelType? ghostType;
  final bool isPeg;
  final String? pegOrderId;
  final int? pegDetectedConfs;
  final String? pegReceiveAddress;
  final bool isBoltz;
  final String? boltzOrderId;
  final String? boltzClaimTxId;
  final bool isSwapOrder;
  final SwapServiceSource? swapServiceSource;
  final String? swapOrderId;
  final Asset? swapFromAsset;
  final Asset? swapToAsset;
  final SwapOrderStatus? swapOrderStatus;
  final int? swapDepositAmount; // Amount being sent/deposited

  TransactionScenario({
    required this.asset,
    required this.type,
    required this.amount,
    required this.confirmations,
    required this.timestamp,
    required this.txhash,
    this.swapOutgoingAssetId,
    this.swapIncomingAssetId,
    this.swapOutgoingAmount,
    this.swapIncomingAmount,
    this.isGhost = false,
    this.ghostType,
    this.isPeg = false,
    this.pegOrderId,
    this.pegDetectedConfs,
    this.pegReceiveAddress,
    this.isBoltz = false,
    this.boltzOrderId,
    this.boltzClaimTxId,
    this.isSwapOrder = false,
    this.swapServiceSource,
    this.swapOrderId,
    this.swapFromAsset,
    this.swapToAsset,
    this.swapOrderStatus,
    this.swapDepositAmount,
  });

  GdkTransaction toGdkTransaction(int currentBlockHeight) {
    final txBlockHeight =
        confirmations > 0 ? currentBlockHeight - confirmations + 1 : 0;

    // Boltz/Lightning transactions are on-chain LBTC transactions
    // so their satoshi should be keyed by LBTC's asset ID
    final satoshiAssetId = isBoltz ? Asset.lbtc().id : asset.id;

    // For peg transactions with receiveAddress, add outputs to enable matching
    final outputs = pegReceiveAddress != null
        ? [GdkTransactionInOut(address: pegReceiveAddress, isRelevant: true)]
        : null;

    return GdkTransaction(
      txhash: txhash,
      type: type,
      createdAtTs: timestamp.microsecondsSinceEpoch,
      blockHeight: txBlockHeight,
      satoshi: {satoshiAssetId: amount},
      swapOutgoingAssetId: swapOutgoingAssetId,
      swapIncomingAssetId: swapIncomingAssetId,
      swapOutgoingSatoshi: swapOutgoingAmount,
      swapIncomingSatoshi: swapIncomingAmount,
      outputs: outputs,
      fee: 1000,
    );
  }

  TransactionDbModel? toDbTransaction() {
    if (!isGhost && !isPeg && !isBoltz && !isSwapOrder) return null;

    TransactionDbModelType? dbType;
    if (isPeg) {
      dbType = type == GdkTransactionTypeEnum.incoming
          ? TransactionDbModelType.sideswapPegIn
          : TransactionDbModelType.sideswapPegOut;
    } else if (isBoltz) {
      // Boltz swap types based on direction
      // incoming = Lightning → On-chain = reverse swap
      // outgoing = On-chain → Lightning = submarine swap
      dbType = type == GdkTransactionTypeEnum.incoming
          ? TransactionDbModelType.boltzReverseSwap
          : TransactionDbModelType.boltzSwap;
    } else {
      dbType = ghostType;
    }

    return TransactionDbModel(
      txhash: txhash,
      type: dbType,
      assetId: asset.id,
      isGhost: isGhost,
      // Boltz and ghost transactions need these fields for pending UI
      ghostTxnCreatedAt: (isGhost || isBoltz) ? timestamp : null,
      // ghostTxnAmount should be stored as absolute value
      // The strategy will apply the sign based on transaction direction
      ghostTxnAmount: (isGhost || isBoltz) ? amount.abs() : null,
      serviceOrderId: pegOrderId ?? boltzOrderId ?? swapOrderId,
    );
  }

  PegOrderDbModel? toPegOrder() {
    if (!isPeg || pegOrderId == null) return null;

    // Create a proper SwapPegStatusResult JSON structure
    final detectedConfs = pegDetectedConfs ?? confirmations;
    final totalConfs = asset.isBTC
        ? onchainConfirmationBlockCount
        : liquidConfirmationBlockCount;

    // Create a transaction with txState set to something that indicates pending
    // Use "Processing" state which indicates pending but not done
    final statusJson = '''
    {
      "list": [
        {
          "tx_hash": "$txhash",
          "tx_state": "Processing",
          "detected_confs": $detectedConfs,
          "total_confs": $totalConfs,
          "amount": ${amount.abs()},
          "created_at": ${timestamp.millisecondsSinceEpoch ~/ 1000}
        }
      ],
      "order_id": "$pegOrderId",
      "peg_in": ${type == GdkTransactionTypeEnum.incoming}
    }
    ''';

    return PegOrderDbModel(
      orderId: pegOrderId!,
      isPegIn: type == GdkTransactionTypeEnum.incoming,
      amount: amount.abs(),
      statusJson: statusJson,
      txhash: txhash,
      receiveAddress: pegReceiveAddress,
      createdAt: timestamp,
    );
  }

  BoltzSwapDbModel? toBoltzOrder() {
    if (!isBoltz || boltzOrderId == null) return null;

    // SwapType.reverse = Lightning → On-chain (incoming/receive)
    // SwapType.submarine = On-chain → Lightning (outgoing/send)
    return BoltzSwapDbModel(
      id: Isar.autoIncrement,
      boltzId: boltzOrderId!,
      claimTxId: boltzClaimTxId,
      invoice: 'lnbc...',
      kind: type == GdkTransactionTypeEnum.incoming
          ? boltz.SwapType.reverse
          : boltz.SwapType.submarine,
      network: boltz.Chain.liquidTestnet,
      hashlock: 'test_hashlock',
      receiverPubkey: 'test_receiver',
      senderPubkey: 'test_sender',
      outAmount: amount.abs(),
      blindingKey: 'test_blinding',
      locktime: 123456,
      scriptAddress: 'test_script_address',
    );
  }

  SwapOrderDbModel? toSwapOrder() {
    if (!isSwapOrder || swapOrderId == null || swapServiceSource == null) {
      return null;
    }

    final fromAsset = swapFromAsset ?? asset;
    final toAsset = swapToAsset ?? asset;
    final status = swapOrderStatus ?? SwapOrderStatus.processing;

    // For swap orders, the amount represents the received amount (settleAmount)
    // Use swapDepositAmount if available, otherwise estimate
    final settleAmount = amount.abs();
    final depositAmount = swapDepositAmount ?? (settleAmount * 105 ~/ 100);

    return SwapOrderDbModel(
      orderId: swapOrderId!,
      createdAt: timestamp,
      fromAsset: fromAsset.id,
      toAsset: toAsset.id,
      depositAddress: 'deposit_address_$swapOrderId',
      settleAddress: 'settle_address_$swapOrderId',
      depositAmount: depositAmount.toString(),
      settleAmount: settleAmount.toString(),
      serviceFeeType: SwapFeeType.percentageFee,
      serviceFeeValue: '0.05', // 5% fee
      serviceFeeCurrency: SwapFeeCurrency.usd,
      status: status,
      type: SwapOrderType.variable,
      serviceType: swapServiceSource!,
      onchainTxHash: txhash,
      updatedAt: timestamp,
    );
  }
}

/// The built scenario environment with all necessary mock data
class ScenarioEnvironment {
  final List<TransactionScenario> scenarios;
  final List<Asset> assets;
  final int currentBlockHeight = 1000000; // Arbitrary high number

  ScenarioEnvironment(this.scenarios, this.assets);

  /// Get network transactions for a specific asset
  List<GdkTransaction> getNetworkTransactions(Asset asset) {
    return scenarios
        .where((s) {
          // Non-ghost transactions matching the asset
          if (s.asset.id == asset.id && !s.isGhost) return true;
          // Boltz/Lightning transactions also appear on LBTC page
          if (asset.isLBTC && s.isBoltz && !s.isGhost) return true;
          return false;
        })
        .map((s) => s.toGdkTransaction(currentBlockHeight))
        .toList();
  }

  /// Get DB transactions (ghost, peg, boltz)
  List<TransactionDbModel> getDbTransactions() {
    return scenarios
        .map((s) => s.toDbTransaction())
        .whereType<TransactionDbModel>()
        .toList();
  }

  /// Get peg orders
  List<PegOrderDbModel> getPegOrders() {
    return scenarios
        .map((s) => s.toPegOrder())
        .whereType<PegOrderDbModel>()
        .toList();
  }

  /// Get Boltz orders
  List<BoltzSwapDbModel> getBoltzOrders() {
    return scenarios
        .map((s) => s.toBoltzOrder())
        .whereType<BoltzSwapDbModel>()
        .toList();
  }

  /// Get swap orders (Sideshift, Changelly)
  List<SwapOrderDbModel> getSwapOrders() {
    return scenarios
        .map((s) => s.toSwapOrder())
        .whereType<SwapOrderDbModel>()
        .toList();
  }

  /// Get confirmation count for a transaction
  int getConfirmationCount(Asset asset, int transactionBlockHeight) {
    if (transactionBlockHeight == 0) return 0;
    return currentBlockHeight - transactionBlockHeight + 1;
  }

  /// Create a ProviderContainer with all necessary overrides
  ProviderContainer createContainer({
    required FormatService formatService,
    required TxnFailureService txnFailureService,
    AquaProvider? mockAqua,
  }) {
    final mockAquaProvider = mockAqua ?? MockAquaProvider();
    final mockLocalizations = MockAppLocalizations();
    final mockConfirmationService = MockConfirmationService();
    final mockBitcoinProvider = MockBitcoinProvider();
    final mockLiquidProvider = MockLiquidProvider();

    // Setup confirmation service with smart defaults
    setupConfirmationServiceDefaults(mockConfirmationService);

    // Override getConfirmationCount to use scenario-aware block heights
    when(() => mockConfirmationService.getConfirmationCount(any(), any()))
        .thenAnswer((invocation) async {
      final asset = invocation.positionalArguments[0] as Asset;
      final blockHeight = invocation.positionalArguments[1] as int;
      return getConfirmationCount(asset, blockHeight);
    });

    when(() => mockConfirmationService.getRequiredConfirmationCount(any()))
        .thenAnswer((invocation) {
      final asset = invocation.positionalArguments[0] as Asset;
      return asset.isBTC
          ? onchainConfirmationBlockCount
          : liquidConfirmationBlockCount;
    });

    // Override isTransactionPending to handle peg transactions
    when(() => mockConfirmationService.isTransactionPending(
          transaction: any(named: 'transaction'),
          asset: any(named: 'asset'),
          dbTransaction: any(named: 'dbTransaction'),
        )).thenAnswer((invocation) async {
      final transaction =
          invocation.namedArguments[#transaction] as GdkTransaction;
      final asset = invocation.namedArguments[#asset] as Asset;
      final dbTransaction =
          invocation.namedArguments[#dbTransaction] as TransactionDbModel?;

      if (dbTransaction != null && dbTransaction.isPeg) {
        return true;
      }

      final confirmationCount =
          await mockConfirmationService.getConfirmationCount(
        asset,
        transaction.blockHeight ?? 0,
      );
      final requiredConfirmations = asset.isBTC
          ? onchainConfirmationBlockCount
          : liquidConfirmationBlockCount;

      return confirmationCount < requiredConfirmations;
    });

    // Setup bitcoin and liquid providers to return empty transaction lists
    when(() => mockBitcoinProvider.getTransactions(
          requiresRefresh: any(named: 'requiresRefresh'),
          details: any(named: 'details'),
        )).thenAnswer((_) async => []);
    when(() => mockLiquidProvider.getTransactions(
          requiresRefresh: any(named: 'requiresRefresh'),
          details: any(named: 'details'),
        )).thenAnswer((_) async => []);

    // Setup aqua provider to return confirmation counts
    when(() => mockAquaProvider.getConfirmationCount(
          asset: any(named: 'asset'),
          transactionBlockHeight: any(named: 'transactionBlockHeight'),
        )).thenAnswer((invocation) {
      final blockHeight =
          invocation.namedArguments[#transactionBlockHeight] as int;
      final asset = invocation.namedArguments[#asset] as Asset;
      final confirmations = getConfirmationCount(asset, blockHeight);
      return Stream.value(confirmations);
    });

    // Setup mock swap storage notifier with swap orders
    final swapOrders = getSwapOrders();
    final mockSwapStorage = MockSwapOrderStorageNotifier(orders: swapOrders);
    when(() => mockSwapStorage.getPendingSettlementSwapsForAssets(
          depositAsset: any(named: 'depositAsset'),
          settleAsset: any(named: 'settleAsset'),
        )).thenAnswer((invocation) async {
      final depositAsset = invocation.namedArguments[#depositAsset] as Asset?;
      final settleAsset = invocation.namedArguments[#settleAsset] as Asset?;

      // Filter swap orders by assets
      return swapOrders.where((order) {
        final matchesDeposit =
            depositAsset == null || order.fromAsset == depositAsset.id;
        final matchesSettle =
            settleAsset == null || order.toAsset == settleAsset.id;
        return matchesDeposit &&
            matchesSettle &&
            order.status.isPendingSettlement;
      }).toList();
    });

    return ProviderContainer(
      overrides: [
        // Network transactions per asset
        for (final asset in assets)
          networkTransactionsProvider(asset).overrideWith(
            (_) => Stream.value(getNetworkTransactions(asset)),
          ),

        // Storage providers
        transactionStorageProvider.overrideWith(
          () =>
              MockTransactionStorageProvider(transactions: getDbTransactions()),
        ),
        pegStorageProvider.overrideWith(
          () => MockPegStorageNotifier(orders: getPegOrders()),
        ),
        boltzStorageProvider.overrideWith(
          () => MockBoltzStorageProvider(swaps: getBoltzOrders()),
        ),
        swapStorageProvider.overrideWith(() => mockSwapStorage),

        // Services
        formatProvider.overrideWith((_) => formatService),
        txnFailureServiceProvider.overrideWith((_) => txnFailureService),
        confirmationServiceProvider
            .overrideWith((_) => mockConfirmationService),
        aquaProvider.overrideWith((_) => mockAquaProvider),
        appLocalizationsProvider.overrideWith((_) => mockLocalizations),
        bitcoinProvider.overrideWith((_) => mockBitcoinProvider),
        liquidProvider.overrideWith((_) => mockLiquidProvider),

        // Assets - ensure ALL assets are included (critical for swap transactions)
        // Swap transactions require both assets to be available
        availableAssetsProvider.overrideWith((_) async {
          // Verify both swap assets are present for all swap scenarios
          final assetIds = assets.map((a) => a.id).toSet();
          for (final scenario in scenarios) {
            if (scenario.type == GdkTransactionTypeEnum.swap) {
              if (scenario.swapIncomingAssetId != null) {
                assert(
                  assetIds.contains(scenario.swapIncomingAssetId),
                  'Swap incoming asset ${scenario.swapIncomingAssetId} not found in assets list. Available: ${assetIds.join(", ")}',
                );
              }
              if (scenario.swapOutgoingAssetId != null) {
                assert(
                  assetIds.contains(scenario.swapOutgoingAssetId),
                  'Swap outgoing asset ${scenario.swapOutgoingAssetId} not found in assets list. Available: ${assetIds.join(", ")}',
                );
              }
            }
          }
          return assets;
        }),
        assetsProvider.overrideWith(() => MockAssetsNotifier(assets: assets)),
      ],
    );
  }
}
