import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';

final sideshiftReceiveProvider = AutoDisposeAsyncNotifierProviderFamily<
    _Notifier, SideshiftVariableOrderResponse?, Asset>(_Notifier.new);

class _Notifier extends AutoDisposeFamilyAsyncNotifier<
    SideshiftVariableOrderResponse?, Asset> {
  @override
  FutureOr<SideshiftVariableOrderResponse?> build(Asset arg) async {
    state = const AsyncValue.loading();
    final pair = SideshiftAssetPair(
      from: arg == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
      to: SideshiftAsset.usdtLiquid(),
    );

    try {
      final sideshiftHttp = ref.read(sideshiftHttpProvider);
      // Fetch permissions and pairInfo in parallel
      final results = await Future.wait([
        sideshiftHttp.checkPermissions(),
        sideshiftHttp.fetchSideShiftAssetPair(pair.from, pair.to)
      ]);

      final permissionsRes = results[0] as SideshiftPermissionsResponse;
      final info = results[1] as SideShiftAssetPairInfo;

      // No permission error
      if (!permissionsRes.createShift) {
        logger.d("[Receive][SideShift] Permission exception triggered");
        state = AsyncValue.error(NoPermissionsException(), StackTrace.empty);
      }

      ref.read(sideshiftAssetPairInfoProvider(pair).notifier).setPairInfo(info);

      final deliverAsset = pair.from;
      final receiveAsset = pair.to;
      logger.d('[Receive][SideShift] $deliverAsset -> $receiveAsset');

      // get receive address
      final isBTC = receiveAsset.network == bitcoinNetwork;
      final address = isBTC
          ? await ref.read(bitcoinProvider).getReceiveAddress()
          : await ref.read(liquidProvider).getReceiveAddress();
      final receiveAddressValue = address?.address;
      if (receiveAddressValue == null) {
        logger.d('[Receive][SideShift] Receive address is null');
        final error = ReceivingAddressException();
        return Future.error(error);
      }

      final order = await _placeVariableRateOrder(
        deliverAsset: deliverAsset,
        receiveAsset: receiveAsset,
        receiveAddress: receiveAddressValue,
      );
      logger.d('[Receive][SideShift] Receive Order Success: $order');
      return order;
    } catch (error) {
      logger.e("[Receive][SideShift] Error: $error", error, StackTrace.current);
      if (error is GdkNetworkException) {
        setOrderError(GdkTransactionException(error));
      } else if (error is OrderException) {
        setOrderError(error);
      }
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  Future<SideshiftVariableOrderResponse> _placeVariableRateOrder({
    required SideshiftAsset deliverAsset,
    required SideshiftAsset receiveAsset,
    required String receiveAddress,
    String? refundAddress,
  }) async {
    final response = await ref.read(sideshiftHttpProvider).requestVariableOrder(
          refundAddress: refundAddress,
          receiveAddress: receiveAddress,
          depositCoin: deliverAsset.coin.toLowerCase(),
          depositNetwork: deliverAsset.network.toLowerCase(),
          settleCoin: receiveAsset.coin.toLowerCase(),
          settleNetwork: receiveAsset.network.toLowerCase(),
        );

    // cache order with empty status
    if (response.id != null) {
      final orderId = response.id!;
      final res = SideshiftOrderStatusResponse(id: orderId);
      await _saveResponseToDatabase(orderId: orderId, response: res);
    }

    return response;
  }

  Future<void> _saveResponseToDatabase({
    required String orderId,
    required SideshiftOrderStatusResponse response,
  }) async {
    final model = SideshiftOrderDbModel.fromSideshiftOrderResponse(response);
    await ref
        .read(sideshiftStorageProvider.notifier)
        .save(model.copyWith(orderId: orderId));
  }
}
