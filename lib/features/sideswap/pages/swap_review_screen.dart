import 'package:coin_cz/features/auth/auth_wrapper.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapReviewScreen extends HookConsumerWidget {
  static const routeName = '/swapReviewScreen';

  const SwapReviewScreen({super.key, required this.arg});
  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(false);

    final content = useMemoized(() {
      final input = ref.read(sideswapInputStateProvider);
      if (arg is SwapStartWebResponse &&
          (arg as SwapStartWebResponse).result != null) {
        // TODO: investigate why we need typecasting here, even after the if check
        return Column(
          children: [
            SwapReviewInfoCard(
              order: (arg as SwapStartWebResponse).result!,
              input: input,
            ),
            const SizedBox(height: 12.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const TransactionFeeBreakdownCard(
                args: FeeStructureArguments.sideswap(),
              ),
            ),
            const SizedBox(height: 20.0),
            SwapSlider(
              onConfirm: () =>
                  ref.read(swapProvider.notifier).executeTransaction(),
            ),
            const SizedBox(height: kBottomPadding),
          ],
        );
      } else if (arg is SwapPegReviewModel) {
        return PegOrderDetails(
          data: arg as SwapPegReviewModel,
          input: input,
        );
      }
    }, [arg]);

    ref.listen(
      swapProvider,
      (_, value) => value.maybeWhen(
        data: (data) => data.maybeMap(
          success: (state) async {
            // ignore: use_build_context_synchronously
            context.pushReplacement(
              SwapAssetCompleteScreen.routeName,
              extra: state,
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

            context.go(AuthWrapper.routeName);
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
        foregroundColor: Theme.of(context).colors.onBackground,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        onBackPressed: () {
          ref.invalidate(sideswapInputStateProvider);
          ref.invalidate(sideswapWebsocketProvider);
          ref.invalidate(pegProvider);
        },
      ),
      backgroundColor: Theme.of(context).colors.swapReviewScreenBackgroundColor,
      body: Container(
        padding: EdgeInsets.only(
          top: context.adaptiveDouble(mobile: 24.0, smallMobile: 10.0),
        ),
        child: SingleChildScrollView(child: content),
      ),
    );
  }
}
