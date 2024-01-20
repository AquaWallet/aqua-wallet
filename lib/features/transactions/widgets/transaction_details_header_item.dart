import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

class TransactionDetailsHeaderItem extends StatelessWidget {
  const TransactionDetailsHeaderItem({
    Key? key,
    required this.uiModel,
  }) : super(key: key);

  final AssetTransactionDetailsHeaderItemUiModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(uiModel.type,
                  style: Theme.of(context).textTheme.headlineMedium),
              uiModel.showPendingIndicator
                  ? Padding(
                      padding: EdgeInsets.only(left: 12.w, top: 1.h),
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 12.w,
                          right: 12.w,
                          top: 4.h,
                          bottom: 4.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20.r),
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!
                              .assetTransactionDetailsPending,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 16.sp,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 18.h),
            child: Text(uiModel.date,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
