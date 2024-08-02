import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:lottie/lottie.dart';

class InternalSendCompleteScreen extends HookConsumerWidget {
  static const routeName = '/internalSendCompleteScreen';

  const InternalSendCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as InternalSendArguments;

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: false,
        title: context.loc.internalSendTitle,
      ),
      extendBodyBehindAppBar: true,
      body: arguments.maybeWhen(
        swapSuccess: (state) => _SwapSuccessUi(
          uiModel: ref.read(swapDetailsProvider(state)),
        ),
        pegSuccess: (state) => _PegSuccessUi(
          uiModel: ref.read(pegDetailsProvider(state)),
        ),
        orElse: () => throw ArgumentError('Invalid arguments'),
      ),
    );
  }
}

class _SwapSuccessUi extends StatelessWidget {
  const _SwapSuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        children: [
          SizedBox(height: 95.h),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 140.r,
            height: 140.r,
            fit: BoxFit.contain,
          ),
          //ANCHOR - Amount Title
          Text(
            context.loc.internalSendSuccessTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: .8,
                ),
          ),
          //ANCHOR - Amount
          Text(
            '${uiModel.receiveAmount} ${uiModel.receiveTicker}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: 38.h),
          //ANCHOR - Fee Breakdown
          InternalSendFeeBreakdownCard(uiModel: uiModel),
          SizedBox(height: 20.h),
          //ANCHOR - Transaction ID
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.h),
                //ANCHOR - Transaction ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.internalSendSuccessTxnIdLabel,
                  value: uiModel.transactionId,
                ),
                SizedBox(height: 16.h),
                //ANCHOR - Order ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.internalSendSuccessOrderIdLabel,
                  value: uiModel.sideswapOrderId,
                ),
                SizedBox(height: 16.h),
                //ANCHOR - Time
                TransactionInfoItem(
                  label: context.loc.swapScreenSuccessTimeLabel,
                  value: uiModel.time,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                SizedBox(height: 18.h),
                //ANCHOR - Date
                TransactionInfoItem(
                  label: context.loc.swapScreenSuccessDateLabel,
                  value: uiModel.date,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                SizedBox(height: 26.h),
              ],
            ),
          ),
          const Spacer(),
          //ANCHOR - Button
          SizedBox(
            width: double.maxFinite,
            child: BoxShadowElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(
                context.loc.sendAssetCompleteScreenDoneButton,
              ),
            ),
          ),
          SizedBox(height: kBottomPadding),
        ],
      ),
    );
  }
}

class _PegSuccessUi extends StatelessWidget {
  const _PegSuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        children: [
          SizedBox(height: 95.h),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 140.r,
            height: 140.r,
            fit: BoxFit.contain,
          ),
          //ANCHOR - Amount Title
          Text(
            context.loc.internalSendSuccessTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: .8,
                ),
          ),
          //ANCHOR - Amount
          Text(
            '${uiModel.receiveAmount} ${uiModel.receiveTicker}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: 38.h),
          //ANCHOR - Fee Breakdown
          InternalSendFeeBreakdownCard(uiModel: uiModel),
          SizedBox(height: 20.h),
          //ANCHOR - Transaction ID
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.h),
                //ANCHOR - Transaction ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.internalSendSuccessTxnIdLabel,
                  value: uiModel.transactionId,
                ),
                SizedBox(height: 16.h),
                //ANCHOR - Order ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.internalSendSuccessOrderIdLabel,
                  value: uiModel.sideswapOrderId,
                ),
                SizedBox(height: 16.h),
                //ANCHOR - Time
                TransactionInfoItem(
                  label: context.loc.swapScreenSuccessTimeLabel,
                  value: uiModel.time,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                SizedBox(height: 18.h),
                //ANCHOR - Date
                TransactionInfoItem(
                  label: context.loc.swapScreenSuccessDateLabel,
                  value: uiModel.date,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                SizedBox(height: 26.h),
              ],
            ),
          ),
          const Spacer(),
          //ANCHOR - Button
          SizedBox(
            width: double.maxFinite,
            child: BoxShadowElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(
                context.loc.sendAssetCompleteScreenDoneButton,
              ),
            ),
          ),
          SizedBox(height: kBottomPadding),
        ],
      ),
    );
  }
}

class _ExpandableTransactionDetailItem extends StatelessWidget {
  const _ExpandableTransactionDetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ExpandableContainer(
      padding: EdgeInsets.only(left: 26.w, right: 20.w),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      child: CopyableTextView(
        margin: EdgeInsetsDirectional.only(top: 4.h, end: 6.w),
        text: value,
      ),
    );
  }
}
