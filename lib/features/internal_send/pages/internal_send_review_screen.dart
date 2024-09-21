import 'dart:async';

import 'package:aqua/constants.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class InternalSendReviewScreen extends HookConsumerWidget {
  static const routeName = '/internalSendReviewScreen';

  const InternalSendReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as InternalSendArguments;
    final isProcessing = useState(false);

    final onInternalSendComplete = useCallback((InternalSendArguments state) {
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed(
          InternalSendCompleteScreen.routeName,
          arguments: state,
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
              destination: InternalSendAmountScreen.routeName,
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
              destination: InternalSendAmountScreen.routeName,
            );
          },
          loading: () => isProcessing.value = true,
        ),
      );

    if (isProcessing.value) {
      return const TransactionProcessingAnimation();
    }

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.internalSendReviewScreenTitle,
        showActionButton: false,
        backgroundColor: context.colors.swapReviewScreenBackgroundColor,
        foregroundColor: context.colorScheme.onBackground,
        iconBackgroundColor:
            context.colors.addressFieldContainerBackgroundColor,
        iconForegroundColor: context.colorScheme.onBackground,
      ),
      backgroundColor: context.colors.swapReviewScreenBackgroundColor,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 28.h),
                  //ANCHOR - Amounts
                  InternalSendSwapReviewAmountsCard(
                    arguments: arguments,
                  ),
                  SizedBox(height: 20.h),
                  //ANCHOR - Fee Estimates
                  if (arguments is InternalSendPegReviewArguments) ...[
                    InternalSendReviewFeeEstimatesCard(
                      arguments: arguments,
                    ),
                    SizedBox(height: 20.h),
                  ],
                  //ANCHOR - Order ID
                  InternalSendReviewOrderIdCard(
                    arguments: arguments,
                  ),
                  SizedBox(height: 20.h),
                  //ANCHOR - Peg Transaction Warning
                  PegInfoMessageView(
                    fontSize: 14.sp,
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 10.h,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
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
            SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }
}
