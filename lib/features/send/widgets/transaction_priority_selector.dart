// ignore_for_file: unnecessary_null_comparison

import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TransactionPrioritySelector extends HookConsumerWidget {
  const TransactionPrioritySelector({
    required this.transaction,
    super.key,
  });

  final SendAssetOnchainTx transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GdkNewTransactionReply? gdkTransaction = useMemoized(() {
      return transaction.maybeMap(
        gdkTx: (tx) => tx.gdkTx,
        orElse: () => null,
      );
    }, [transaction]);

    final isExpanded = useState<bool>(true);
    final rates = ref
        .watch(fetchedFeeRatesPerVByteProvider(NetworkType.bitcoin))
        .asData
        ?.value;
    final selectedFeeRate = ref.watch(userSelectedFeeRatePerVByteProvider);
    logger.d(
        '[Send][Fee] selectedFeeRate: ${selectedFeeRate?.priority.toString()}');

    final selectedPriority =
        selectedFeeRate?.priority ?? TransactionPriority.medium;

    int calculateFeeInSats(int feeRate) {
      return gdkTransaction != null
          ? (gdkTransaction.transactionVsize! * feeRate).toInt()
          : 0;
    }

    final highFeeRate = rates?[TransactionPriority.high]!.toInt() ?? 0;
    final highFeeInSats = calculateFeeInSats(highFeeRate);
    final highFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), highFeeInSats)));

    final mediumFeeRate = rates?[TransactionPriority.medium]!.toInt() ?? 0;
    final mediumFeeInSats = calculateFeeInSats(mediumFeeRate);
    final mediumFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), mediumFeeInSats)));

    final lowFeeRate = rates?[TransactionPriority.low]!.toInt() ?? 0;
    final lowFeeInSats = calculateFeeInSats(lowFeeRate);
    final lowFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), lowFeeInSats)));

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(isExpanded: isExpanded),
          if (isExpanded.value) ...[
            Container(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SelectionItem(
                          label: context
                              .loc.sendAssetReviewScreenConfirmPriorityHigh,
                          fee: highFeeInFiat ?? '',
                          satsPerByte: highFeeRate.toInt(),
                          isSelected:
                              selectedPriority == TransactionPriority.high,
                          onPressed: () => ref
                                  .read(userSelectedFeeRatePerVByteProvider
                                      .notifier)
                                  .state =
                              FeeRate(TransactionPriority.high,
                                  highFeeRate.toDouble()),
                        ),
                      ),
                      SizedBox(
                        width: 11.w,
                      ),
                      Expanded(
                          child: _SelectionItem(
                        label: context
                            .loc.sendAssetReviewScreenConfirmPriorityStandard,
                        fee: mediumFeeInFiat ?? '',
                        satsPerByte: mediumFeeRate.toInt(),
                        isSelected:
                            selectedPriority == TransactionPriority.medium,
                        onPressed: () =>
                            ref
                                    .read(userSelectedFeeRatePerVByteProvider
                                        .notifier)
                                    .state =
                                FeeRate(TransactionPriority.medium,
                                    mediumFeeRate.toDouble()),
                      )),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: _SelectionItem(
                          label: context
                              .loc.sendAssetReviewScreenConfirmPriorityLow,
                          fee: lowFeeInFiat ?? '',
                          satsPerByte: lowFeeRate.toInt(),
                          isSelected:
                              selectedPriority == TransactionPriority.low,
                          onPressed: () => ref
                                  .read(userSelectedFeeRatePerVByteProvider
                                      .notifier)
                                  .state =
                              FeeRate(TransactionPriority.low,
                                  lowFeeRate.toDouble()),
                        ),
                      ),
                      SizedBox(
                        width: 11.w,
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _SelectionItem extends StatelessWidget {
  const _SelectionItem({
    required this.label,
    required this.fee,
    required this.satsPerByte,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final String fee;
  final int satsPerByte;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.background,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6.r),
        child: Ink(
          height: 125.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: isSelected
              ? null
              : BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colors
                        .sendAssetPriorityUnselectedBorder,
                    width: 2.r,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context)
                              .colors
                              .sendAssetPrioritySelectedText
                          : Theme.of(context).colorScheme.onBackground,
                    ),
              ),
              const Spacer(),
              Text(
                fee,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context)
                              .colors
                              .sendAssetPrioritySelectedText
                          : Theme.of(context).colorScheme.onBackground,
                    ),
              ),
              SizedBox(height: 5.h),
              Text(
                context.loc
                    .sendAssetReviewScreenConfirmPrioritySats(satsPerByte),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context)
                              .colors
                              .sendAssetPrioritySelectedText
                          : Theme.of(context).colorScheme.onBackground,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isExpanded,
  });

  final ValueNotifier<bool> isExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => isExpanded.value = !isExpanded.value,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  context.loc.sendAssetReviewScreenConfirmPriorityTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18.sp,
                      ),
                ),
              ),
              ExpandIcon(
                onPressed: null,
                disabledColor: Theme.of(context).colorScheme.onBackground,
                expandedColor: Theme.of(context).colorScheme.onBackground,
                isExpanded: isExpanded.value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
