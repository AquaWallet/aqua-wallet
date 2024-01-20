import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapIdCard extends StatelessWidget {
  const SwapIdCard({
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
          SizedBox(height: 9.h),
          //ANCHOR - Transaction ID
          ExpandableContainer(
            padding: EdgeInsets.only(left: 26.w, right: 6.w),
            title: Text(
              AppLocalizations.of(context)!.swapScreenSuccessTransactionIdLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            child: CopyableTextView(text: uiModel.transactionId),
          ),
          //ANCHOR - Time
          TransactionInfoItem(
            label: AppLocalizations.of(context)!.swapScreenSuccessTimeLabel,
            value: uiModel.time,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Date
          TransactionInfoItem(
            label: AppLocalizations.of(context)!.swapScreenSuccessDateLabel,
            value: uiModel.date,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 26.h),
        ],
      ),
    );
  }
}
