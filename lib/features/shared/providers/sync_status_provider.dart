import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/data/services/mempool_api_service.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.statusManager);

const int kStatusCheckPeriodSeconds = 60;

final syncStatusProvider =
    AsyncNotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);

class SyncStatusNotifier extends AsyncNotifier<SyncStatus> {
  SyncStatusNotifier();

  Timer? _statusCheckTimer;

  @override
  FutureOr<SyncStatus> build() async {
    // Start with optimistic assumption that we're connected
    const initialState = SyncStatus(
      isDeviceConnected: true, // Assume connected initially
      lastBitcoinBlock: null,
      lastLiquidBlock: null,
      initialized: false,
    );

    // Register cleanup when the provider is disposed
    ref.onDispose(() {
      _statusCheckTimer?.cancel();
    });

    // Start the sync process immediately
    startSync();

    return initialState;
  }

  Future<void> checkSync() async {
    _logger
        .info("Checking sync status by comparing GDK vs Mempool block heights");

    try {
      final bitcoinBlockHeight = await ref
          .read(mempoolBitcoinApiServiceProvider)
          .getLatestBlockHeight()
          .then((value) => int.tryParse(value.body!));
      final liquidNetworkBlockHeight = await ref
          .read(mempoolLiquidApiServiceProvider)
          .getLatestBlockHeight()
          .then((value) => int.tryParse(value.body!));
      if (bitcoinBlockHeight == null || liquidNetworkBlockHeight == null) {
        _logger.warning(
            "Failed to fetch Mempool block height, skipping sync check");
        return;
      }

      // Get current GDK block height
      final currentState = state.valueOrNull;
      final gdkBitcoinHeight = currentState?.lastBitcoinBlock;
      final liquidHeight = currentState?.lastLiquidBlock;

      if (gdkBitcoinHeight == null || liquidHeight == null) {
        _logger.warning(
            "GDK block height not available - setting sync to unhealthy");
        if (state.hasValue) {
          state = AsyncValue.data(
            state.requireValue.copyWith(isDeviceConnected: false),
          );
        }
        return;
      }

      // Compare heights: if GDK height < Mempool height, something is wrong
      final isConnected = gdkBitcoinHeight >= bitcoinBlockHeight &&
          liquidHeight >= liquidNetworkBlockHeight;
      final bitcoinBlockHeightDiff = bitcoinBlockHeight - gdkBitcoinHeight;
      final liquidHeightDiff = liquidNetworkBlockHeight - liquidHeight;

      _logger.info(
          "Block height comparison GDK: $gdkBitcoinHeight, Mempool: $bitcoinBlockHeight, "
          "Diff: $bitcoinBlockHeightDiff, Connected: $isConnected, Liquid: $liquidHeight, Blockstream Liquid: $liquidNetworkBlockHeight, Liquid Diff: $liquidHeightDiff");

      if (state.hasValue) {
        state = AsyncValue.data(
          state.requireValue.copyWith(isDeviceConnected: isConnected),
        );
      }
    } catch (e, stackTrace) {
      if (state.hasValue && state.valueOrNull != null) {
        state = AsyncValue.data(
          state.valueOrNull!.copyWith(isDeviceConnected: false),
        );
      }
      _logger.error("Error checking sync status", e, stackTrace);
    }
  }

  Future<void> startSync() async {
    _logger.info("Starting sync with Mempool block height comparison");
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: kStatusCheckPeriodSeconds),
      (_) async => await checkSync(),
    );

    await checkSync();

    ref.read(bitcoinProvider).blockHeightEventSubject.stream.listen((block) {
      _logger.info("New Bitcoin block received: $block");

      if (state.hasValue) {
        state = AsyncValue.data(
          state.requireValue.copyWith(lastBitcoinBlock: block),
        );
        // Trigger connection status check when new block arrives
        checkSync();
      }
    });

    ref.read(liquidProvider).blockHeightEventSubject.stream.listen((block) {
      _logger.info("New Liquid block received: $block");

      if (state.hasValue) {
        state = AsyncValue.data(
          state.requireValue.copyWith(lastLiquidBlock: block),
        );
      }
    });

    // Listen to connectivity changes
    ref.listen(connectivityStatusProvider, (_, data) {
      checkSync();
    });

    if (state.hasValue) {
      state = AsyncValue.data(
        state.requireValue.copyWith(initialized: true),
      );
    }
  }
}
