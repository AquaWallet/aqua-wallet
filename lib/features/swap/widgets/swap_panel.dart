import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SwapPanel extends HookConsumerWidget {
  const SwapPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliverFocusNode = useFocusNode();

    final value = ref.watch(swapLoadingIndicatorStateProvider);
    final isLoading = value == const SwapProgressState.connecting();
    final error = ref.watch(swapValidationsProvider(context))?.message;

    deliverFocusNode.addListener(() {
      if (deliverFocusNode.hasFocus) {
        ref.read(sideswapInputStateProvider.notifier)
          ..setUserInputSide(SwapUserInputSide.deliver)
          ..setDeliverAmount(ref.read(swapIncomingDeliverAmountProvider));
      }
    });
    ref.listen(
      sideswapWebsocketSubscribedAssetIdStateProvider,
      (_, __) {},
    );

    return Skeletonizer(
      enabled: isLoading,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: BoxShadowContainer(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
            boxShadow: [Theme.of(context).shadow],
          ),
          padding: EdgeInsets.only(
            top: 114.h,
            bottom: 34.h,
            left: 28.w,
            right: 28.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              //ANCHOR - Deliver Asset
              SwapDeliverAssetPicker(focusNode: deliverFocusNode),
              SizedBox(height: 18.h),
              //ANCHOR - Rate
              const SwapConversionRateView(),
              SizedBox(height: 18.h),
              //ANCHOR - Receive Asset
              const SwapReceiveAssetPicker(),
              SizedBox(height: 18.h),
              //ANCHOR - Error Message
              CustomError(errorMessage: error),
              SizedBox(height: 18.h),
              //ANCHOR - Swap Button
              const SwapButton(),
              //ANCHOR - Peg Info Message
              const PegInfoMessage(),
            ],
          ),
        ),
      ),
    );
  }
}
