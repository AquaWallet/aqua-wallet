import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapReviewScreen extends HookConsumerWidget {
  static const routeName = '/swapReviewScreen';

  const SwapReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)!.settings.arguments;
    final isProcessing = useState(false);

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

    ref.listen(
      swapProvider,
      (_, value) => value.maybeWhen(
        data: (data) => data.maybeMap(
          success: (state) async {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pushReplacementNamed(
              SwapAssetCompleteScreen.routeName,
              arguments: state,
            );
            isProcessing.value = false;

            ref.read(swapLoadingIndicatorStateProvider.notifier).state =
                const SwapProgressState.empty();
            return null;
          },
          orElse: () => null,
        ),
        error: (error, stackTrace) {
          isProcessing.value = false;
          ref.handleSwapError(error, stackTrace);
        },
        loading: () => isProcessing.value = true,
        orElse: () {},
      ),
    );

    ref.listen(
      pegProvider,
      (_, state) => state.maybeWhen(
        data: (data) => data.maybeMap(
          success: (_) {
            isProcessing.value = false;

            Navigator.of(context).popUntil((route) => route.isFirst);
            context.showSuccessSnackbar(
              context.loc.pegInProgress,
            );
            return null;
          },
          orElse: () => null,
        ),
        error: (error, stackTrace) {
          isProcessing.value = false;
          ref.handleSwapError(error, stackTrace);
        },
        loading: () => isProcessing.value = true,
        orElse: () {},
      ),
    );

    if (isProcessing.value) {
      return const TransactionProcessingAnimation();
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
          ref.invalidate(pegProvider);
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
