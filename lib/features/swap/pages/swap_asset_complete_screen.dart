import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:lottie/lottie.dart';

class SwapAssetCompleteScreen extends HookConsumerWidget {
  static const routeName = '/swapAssetCompleteScreen';

  const SwapAssetCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as SwapStateSuccess;

    final uiModel = ref.read(swapDetailsProvider(arguments));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: false,
        title: context.loc.swapScreenTitle,
      ),
      body: _SuccessUi(uiModel: uiModel),
    );
  }
}

class _SuccessUi extends StatelessWidget {
  const _SuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Column(
        children: [
          SizedBox(height: 18.h),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 100.r,
            height: 100.r,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 7.h),
          //ANCHOR - Amount Title
          Text(
            context.loc.swapScreenSuccessAmountTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //ANCHOR - Amount
              Text(
                uiModel.receiveAmount,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(width: 6.w),
              //ANCHOR - Symbol
              Text(
                uiModel.receiveTicker,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AquaColors.graniteGray,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          //ANCHOR - Transaction Info
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 22.h),
                //ANCHOR - Amount
                TransactionInfoItem(
                  label: context.loc.swapScreenSuccessSentAmountLabel,
                  value: uiModel.deliverAmount,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                const SizedBox(height: 18),
                //ANCHOR - Network Fee
                TransactionInfoItem(
                  label: context.loc.sendAssetCompleteScreenFeeLabel,
                  value: uiModel.networkFee,
                  padding: EdgeInsets.symmetric(horizontal: 26.w),
                ),
                SizedBox(height: 18.h),
                //ANCHOR - Notes
                // ExpandableContainer(
                //   padding: EdgeInsets.only(left: 26.w, right: 6.w),
                //   title: Text(
                //     context.loc.sendAssetCompleteScreenNoteLabel,
                //     style: Theme.of(context).textTheme.labelLarge?.copyWith(
                //           color: Theme.of(context).colorScheme.onSurface,
                //           fontWeight: FontWeight.w400,
                //         ),
                //   ),
                //   child: Container(
                //     padding: EdgeInsets.only(bottom: 18.h),
                //     child: Text(
                //       uiModel.note ?? '',
                //       textAlign: TextAlign.start,
                //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
                //             color: Theme.of(context).colorScheme.onBackground,
                //             fontWeight: FontWeight.w400,
                //           ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          //ANCHOR - Transaction ID
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 9.h),
                //ANCHOR - Transaction ID
                ExpandableContainer(
                  padding: EdgeInsets.only(left: 26.w, right: 6.w),
                  title: Text(
                    context.loc.swapScreenSuccessTransactionIdLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  child: CopyableTextView(text: uiModel.transactionId),
                ),
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
