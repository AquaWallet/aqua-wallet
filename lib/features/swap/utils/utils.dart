import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

extension SwapContextExt on WidgetRef {
  void handleSwapError(
    dynamic error,
    StackTrace stackTrace, {
    String destination = SwapScreen.routeName,
  }) {
    logger.e('[Swap] [Error]', error, stackTrace);
    var errorMessage = '';
    if (error is ArgumentError) {
      errorMessage = error.message as String;
    } else if (error is GdkNetworkException) {
      errorMessage = error.errorMessage();
    } else if (error is SideswapHttpStateNetworkError) {
      errorMessage = error.message!;
    } else if (error is TimeoutException) {
      errorMessage = context.loc.internalSendTimeoutError;
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
