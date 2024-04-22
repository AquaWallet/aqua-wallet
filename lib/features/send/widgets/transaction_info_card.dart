import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class TransactionInfoCard extends HookConsumerWidget {
  const TransactionInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(sendAssetProvider);
    final fee = ref.watch(totalFeeToDisplayProvider(asset));

    final amountToDisplay = ref.read(amountMinusFeesToDisplayProvider);

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 22.h),
          //ANCHOR - Amount
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenUsdAmountLabel,
            value: '$amountToDisplay ${asset.symbol}',
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          const SizedBox(height: 18),
          //ANCHOR - Network Fee
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenFeeLabel,
            value: fee ?? '-',
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 22.h),
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
          //       arguments.note ?? '',
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
