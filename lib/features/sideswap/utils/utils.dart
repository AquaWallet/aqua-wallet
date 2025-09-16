import 'dart:async';

import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';

extension SwapContextExt on WidgetRef {
  void handleSwapError(
    dynamic error,
    StackTrace stackTrace, {
    String destination = SwapScreen.routeName,
  }) {
    logger.error('[Swap] [Error]', error, stackTrace);
    var errorMessage = '';
    if (error is ArgumentError) {
      errorMessage = error.message as String;
    } else if (error is GdkNetworkException) {
      errorMessage = error.errorMessage();
    } else if (error is SideswapHttpStateNetworkError) {
      errorMessage = error.message!;
    } else if (error is TimeoutException) {
      errorMessage = context.loc.internalSendTimeoutError;
    } else if (error is PegSideSwapMinBtcLimitException ||
        error is PegSideSwapMinLBtcLimitException) {
      errorMessage = context.loc.genericSwapMinAmountError;
    }

    if (errorMessage.isNotEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CustomDialog(
          child: SwapErrorDialogContent(
            message: errorMessage,
            destinationRouteName: destination,
          ),
        ),
      );
    }
    read(swapLoadingIndicatorStateProvider.notifier).state =
        const SwapProgressState.empty();
  }
}
