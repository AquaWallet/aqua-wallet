import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/features/swaps/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sendAssetSwapOrderReadyProvider =
    Provider.autoDispose.family<bool, SendAssetArguments>(
  (ref, args) {
    final input = ref.watch(sendAssetInputStateProvider(args)).valueOrNull;

    if (input?.asset.isAltUsdt != true || input?.swapPair == null) {
      return true;
    }

    final swapArgs = SwapArgs(pair: input!.swapPair!);
    final swapOrderState = ref.watch(swapOrderProvider(swapArgs));
    return swapOrderState.valueOrNull?.order?.depositAddress != null;
  },
);
