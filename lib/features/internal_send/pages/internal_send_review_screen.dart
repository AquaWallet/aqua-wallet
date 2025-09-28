import 'dart:async';

import 'package:aqua/constants.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InternalSendReviewScreen extends HookConsumerWidget {
  static const routeName = '/internalSendReviewScreen';

  const InternalSendReviewScreen({super.key, required this.arguments});

  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(false);

    final onInternalSendComplete = useCallback((InternalSendArguments state) {
      Future.microtask(() {
        context.pushReplacement(
          InternalSendCompleteScreen.routeName,
          extra: state,
        );
        isProcessing.value = false;
        ref.read(swapLoadingIndicatorStateProvider.notifier).state =
            const SwapProgressState.empty();
      });
      return null;
    });

    ref
      ..listen(
        sideswapWebsocketProvider,
        (_, __) {},
      )
      ..listen(
        swapProvider,
        (_, value) => value.when(
          data: (data) => data.maybeMap(
            success: (state) => onInternalSendComplete(
              InternalSendArguments.swapSuccess(state: state),
            ),
            orElse: () => null,
          ),
          error: (error, stackTrace) {
            isProcessing.value = false;
            ref.handleSwapError(
              error,
              stackTrace,
              destination: AuthWrapper.routeName,
            );
          },
          loading: () => isProcessing.value = true,
        ),
      )
      ..listen(
        pegProvider,
        (_, state) => state.when(
          data: (data) => data.maybeMap(
            success: (state) => onInternalSendComplete(
              InternalSendArguments.pegSuccess(state: state),
            ),
            orElse: () => null,
          ),
          error: (error, stackTrace) {
            isProcessing.value = false;
            ref.handleSwapError(
              error,
              stackTrace,
              destination: AuthWrapper.routeName,
            );
          },
          loading: () => isProcessing.value = true,
        ),
      );

    if (isProcessing.value) {
      return const TransactionProcessingAnimation();
    }

    final reviewTopSpacing = useMemoized(() {
      final height = MediaQuery.of(context).size.height;
      if (height < 600) return 14.0;
      if (height < 700) return 18.0;
      return 20.0;
    }, [MediaQuery.of(context).size.height]);

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.internalSend,
        showActionButton: false,
        backgroundColor: context.colors.swapReviewScreenBackgroundColor,
        foregroundColor: context.colors.onBackground,
        iconBackgroundColor:
            context.colors.addressFieldContainerBackgroundColor,
        iconForegroundColor: context.colors.onBackground,
      ),
      backgroundColor: context.colors.swapReviewScreenBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: reviewTopSpacing),
                      //ANCHOR - Amounts
                      InternalSendSwapReviewAmountsCard(
                        arguments: arguments,
                      ),
                      SizedBox(height: reviewTopSpacing),
                      //ANCHOR - Fee Estimates
                      if (arguments is InternalSendPegReviewArguments) ...[
                        InternalSendReviewFeeEstimatesCard(
                          arguments: arguments,
                        ),
                        SizedBox(height: reviewTopSpacing),
                      ],
                      //ANCHOR - Order ID
                      InternalSendReviewOrderIdCard(
                        arguments: arguments,
                      ),
                      SizedBox(height: reviewTopSpacing),
                      //ANCHOR - Peg Transaction Warning
                      const PegInfoMessageView(
                        fontSize: 14.0,
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
              //ANCHOR - Confirmation Slider
              SwapSlider(
                onConfirm: () => arguments.maybeMap(
                  pegReview: (_) =>
                      ref.read(pegProvider.notifier).executeTransaction(),
                  swapReview: (_) =>
                      ref.read(swapProvider.notifier).executeTransaction(),
                  orElse: () => null,
                ),
              ),
              const SizedBox(height: kBottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
