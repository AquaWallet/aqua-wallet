import 'dart:async';

import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';

final sendAssetSetupProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await SendAssetSetupService(ref).setup();
});

class SendAssetSetupService {
  final AutoDisposeFutureProviderRef ref;

  SendAssetSetupService(this.ref);

  Future<bool> setup() async {
    final asset = ref.watch(sendAssetProvider);
    final lnurlPayParams = ref.read(lnurlParseResultProvider)?.payParams;

    if (asset.isLightning && lnurlPayParams != null) {
      return await setupLnurlp();
    } else if (asset.isLightning) {
      return await ref
          .read(boltzSubmarineSwapProvider.notifier)
          .prepareSubmarineSwap();
    } else if (asset.isSideshift) {
      return await setupSideshift();
    } else if (asset.isBTC) {
      return await setupBtc();
    } else {
      // no setup needed for other assets
      return true;
    }
  }

  Future<bool> setupBtc() async {
    final result =
        ref.watch(fetchedFeeRatesPerVByteProvider(NetworkType.bitcoin));
    final completer = Completer<bool>();

    result.when(
      data: (_) => completer.complete(true),
      error: (error, _) => completer.completeError(error),
      loading: () {}, // don't return, wait for data or error
    );

    return completer.future;
  }

  Future<bool> setupLnurlp() async {
    final lnurlPayParams = ref.read(lnurlParseResultProvider)?.payParams;
    final amount = ref.read(userEnteredAmountProvider)?.toInt();

    if (lnurlPayParams == null) {
      throw Exception('Could not get lnurlPayParams');
    }

    if (amount == null) {
      throw Exception('Could not get amount');
    }

    // get invoice from lnurlp
    final invoice = await ref
        .read(lnurlProvider)
        .callLnurlPay(payParams: lnurlPayParams, amountSatoshis: amount);
    ref.read(sendAddressProvider.notifier).state = invoice;

    // now setup boltz
    return await ref
        .read(boltzSubmarineSwapProvider.notifier)
        .prepareSubmarineSwap();
  }

  Future<bool> setupSideshift() async {
    // check permission
    final permissionsResponse =
        await ref.read(sideshiftHttpProvider).checkPermissions();
    final hasPermissions = permissionsResponse.createShift;
    if (!hasPermissions) {
      throw NoPermissionsException();
    }

    final asset = ref.read(sendAssetProvider);
    final address = ref.read(sendAddressProvider);

    // get pair info
    final SideshiftAssetPair assetPair = SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(),
      to: asset == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
    );

    final currentPairInfo = await ref
        .read(sideshiftHttpProvider)
        .fetchSideShiftAssetPair(assetPair.from, assetPair.to);

    // get refund address
    final refundAddress = await ref.read(liquidProvider).getReceiveAddress();
    logger.d("[Send][Sideshift] refundAddress: $refundAddress");
    if (refundAddress == null) {
      throw Exception('Could not get refund address');
    }

    // start order
    final amount = ref.read(userEnteredAmountProvider);
    await ref
        .read(sideshiftSendProvider)
        .placeSendOrder(
            deliverAsset: assetPair.from,
            receiveAsset: assetPair.to,
            refundAddress: refundAddress.address,
            amount: amount,
            receiveAddress: address,
            exchangeRate: currentPairInfo)
        .catchError((e) {
      throw e;
    });

    return true;
  }
}
