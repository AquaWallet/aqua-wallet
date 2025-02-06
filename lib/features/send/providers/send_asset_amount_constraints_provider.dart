import 'dart:async';

import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';

// This provider deals with various constraints for the send asset amount set
// by the multiple external services.

final sendAssetAmountConstraintsProvider =
    AutoDisposeAsyncNotifierProviderFamily<
        SendAssetAmountConstraintsNotifier,
        SendAssetAmountConstraints,
        SendAssetArguments>(SendAssetAmountConstraintsNotifier.new);

class SendAssetAmountConstraintsNotifier extends AutoDisposeFamilyAsyncNotifier<
    SendAssetAmountConstraints, SendAssetArguments> {
  @override
  FutureOr<SendAssetAmountConstraints> build(SendAssetArguments arg) async {
    final input = await ref.watch(sendAssetInputStateProvider(arg).future);
    final asset = input.asset;

    if (asset.isLightning) {
      final params = input.lnurlData?.payParams;
      return SendAssetAmountConstraints.lightning(params);
    }

    if (asset.isAltUsdt) {
      final swapPair = input.swapPair;
      if (swapPair == null) {
        throw Exception('Swap pair is null');
      }
      final swapCreationNotifier =
          ref.read(swapOrderProvider(SwapArgs(pair: swapPair)).notifier);
      await swapCreationNotifier.getRate();

      final swapState = ref.read(swapOrderProvider(SwapArgs(pair: swapPair)));
      if (swapState.value?.rate != null) {
        return SendAssetAmountConstraints.swap(
            swapState.value!.rate!, asset.precision);
      }
      return SendAssetAmountConstraints.aqua();
    }

    return SendAssetAmountConstraints.aqua();
  }
}
