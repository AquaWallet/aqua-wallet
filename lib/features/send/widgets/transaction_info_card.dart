import 'package:aqua/features/send/providers/send_asset_fee_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';

class TransactionInfoCard extends HookConsumerWidget {
  const TransactionInfoCard({
    super.key,
    required this.arguments,
  });

  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fee = ref.watch(feeInFiatToDisplayProvider(arguments.asset));

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
            label: AppLocalizations.of(context)!
                .sendAssetCompleteScreenUsdAmountLabel,
            value: '$amountToDisplay ${arguments.symbol}',
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          const SizedBox(height: 18),
          //ANCHOR - Network Fee
          TransactionInfoItem(
            label:
                AppLocalizations.of(context)!.sendAssetCompleteScreenFeeLabel,
            value: fee ?? '-',
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 22.h),
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
