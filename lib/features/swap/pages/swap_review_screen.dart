import 'package:aqua/common/widgets/custom_dialog.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapErrorDialogContent extends HookConsumerWidget {
  const SwapErrorDialogContent({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onContinue = useCallback(() {
      ref.invalidate(sideswapInputStateProvider);
      ref.invalidate(sideswapWebsocketProvider);
      Navigator.of(context)
          .popUntil((route) => route.settings.name == SwapScreen.routeName);
    }, []);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            context.loc.swapError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: SizedBox(
              width: double.maxFinite,
              height: 48.h,
              child: BoxShadowElevatedButton(
                onPressed: onContinue,
                child: Text(
                  context.loc.backupRecoveryAlertButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwapReviewScreen extends HookConsumerWidget {
  static const routeName = '/swapReviewScreen';

  const SwapReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)!.settings.arguments;

    final isProcessing = ref.watch(startSwapProvider);
    final amount = ref.read(swapIncomingDeliverAmountProvider);
    final inputState = ref.read(sideswapInputStateProvider);
    final deliverAssetTicker = inputState.deliverAsset?.ticker ?? '';
    final receiveAssetTicker = inputState.receiveAsset?.ticker ?? '';

    final content = useMemoized(() {
      final input = ref.read(sideswapInputStateProvider);
      if (arg is SwapStartWebResponse && arg.result != null) {
        return Column(
          children: [
            SwapReviewInfoCard(
              order: arg.result!,
              input: input,
            ),
            const Spacer(),
            SwapSlider(
              onConfirm: () =>
                  ref.read(swapProvider.notifier).executeTransaction(),
            ),
            SizedBox(height: kBottomPadding),
          ],
        );
      } else if (arg is SwapPegReviewModel) {
        return PegOrderDetails(data: arg, input: input);
      }
    }, [arg]);

    final showErrorDialog = useCallback((String message) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CustomDialog(
          child: SwapErrorDialogContent(message: message),
        ),
      );
    }, []);

    ref.listen(
      swapProvider,
      (_, value) => value.maybeWhen(
        data: (data) => data.maybeWhen(
          success: (asset, transaction) {
            Navigator.of(context).pushReplacementNamed(
              SwapAssetCompleteScreen.routeName,
              arguments: (asset, transaction),
            );
            ref.read(swapLoadingIndicatorStateProvider.notifier).state =
                const SwapProgressState.empty();
            return null;
          },
          orElse: () => null,
        ),
        error: (error, stackTrace) {
          logger.e(error);
          logger.e(stackTrace);

          var errorMessage = '';
          if (error is ArgumentError) {
            errorMessage = error.message as String;
          } else if (error is GdkNetworkException) {
            errorMessage = error.errorMessage();
          } else if (error is SideswapHttpStateNetworkError) {
            errorMessage = error.message!;
          }

          if (errorMessage.isNotEmpty) {
            showErrorDialog(errorMessage);
          }
          ref.read(swapLoadingIndicatorStateProvider.notifier).state =
              const SwapProgressState.empty();
        },
        orElse: () {},
      ),
    );
    ref.listen(
      pegProvider,
      (_, state) => state.asData?.value.maybeWhen(
        success: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.showSuccessSnackbar(
            context.loc.pegInProgress,
          );
          return null;
        },
        orElse: () => null,
      ),
    );

    if (isProcessing) {
      return TransactionProcessingAnimation(
        message: context.loc.swapScreenLoadingMessage(
          amount,
          deliverAssetTicker,
          receiveAssetTicker,
        ),
      );
    }

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.reviewSwap,
        showActionButton: false,
        backgroundColor:
            Theme.of(context).colors.swapReviewScreenBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        onBackPressed: () {
          ref.invalidate(sideswapInputStateProvider);
          ref.invalidate(sideswapWebsocketProvider);
        },
      ),
      backgroundColor: Theme.of(context).colors.swapReviewScreenBackgroundColor,
      body: Container(
        padding: EdgeInsets.only(top: 24.h),
        child: content,
      ),
    );
  }
}
