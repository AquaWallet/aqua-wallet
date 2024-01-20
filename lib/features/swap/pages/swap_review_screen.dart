import 'package:aqua/common/widgets/custom_dialog.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapReviewScreen extends HookConsumerWidget {
  static const routeName = '/swapReviewScreen';

  const SwapReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)!.settings.arguments;

    final isProcessing = ref.watch(startSwapProvider);

    final content = useMemoized(() {
      final input = ref.read(sideswapInputStateProvider);
      if (arg is SwapStartWebResponse && arg.result != null) {
        return SwapOrderDetails(order: arg.result!, input: input);
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
            AppLocalizations.of(context)!.pegInProgress,
          );
          return null;
        },
        orElse: () => null,
      ),
    );

    return isProcessing
        ? const SwapProcessingIndicator()
        : Scaffold(
            appBar: AquaAppBar(
              title: AppLocalizations.of(context)!.reviewSwap,
              showActionButton: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.onBackground,
              iconBackgroundColor: Theme.of(context).colorScheme.background,
              iconForegroundColor: Theme.of(context).colorScheme.onBackground,
              onBackPressed: () {
                ref.invalidate(sideswapInputStateProvider);
                ref.invalidate(sideswapWebsocketProvider);
              },
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Container(
              padding: EdgeInsets.only(top: 24.h),
              child: content,
            ),
          );
  }
}
