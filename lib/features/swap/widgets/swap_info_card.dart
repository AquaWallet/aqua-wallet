import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapInfoCard extends StatelessWidget {
  const SwapInfoCard({
    super.key,
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 22.h),
          //ANCHOR - Amount
          TransactionInfoItem(
            label:
                AppLocalizations.of(context)!.swapScreenSuccessSentAmountLabel,
            value: uiModel.deliverAmount,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          const SizedBox(height: 18),
          //ANCHOR - Network Fee
          TransactionInfoItem(
            label:
                AppLocalizations.of(context)!.sendAssetCompleteScreenFeeLabel,
            value: uiModel.networkFee,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Notes
          // ExpandableContainer(
          //   padding: EdgeInsets.only(left: 26.w, right: 6.w),
          //   title: Text(
          //     AppLocalizations.of(context)!.sendAssetCompleteScreenNoteLabel,
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
    );
  }
}
