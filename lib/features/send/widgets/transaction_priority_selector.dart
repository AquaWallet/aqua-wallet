// ignore_for_file: unnecessary_null_comparison

import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TransactionPrioritySelector extends HookConsumerWidget {
  const TransactionPrioritySelector({
    required this.onFeeRateChange,
    required this.rates,
    required this.gdkTransaction,
    super.key,
  });

  final void Function(int) onFeeRateChange;
  final Map<TransactionPriority, double> rates;
  final GdkNewTransactionReply gdkTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState<bool>(false);
    final selectedPriority =
        useState<TransactionPriority>(TransactionPriority.low);

    final highFeeRate = rates[TransactionPriority.high]!.toInt();
    final highFeeInSats =
        (gdkTransaction.transactionVsize! * highFeeRate).toInt();
    final highFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), highFeeInSats)));

    final mediumFeeRate = rates[TransactionPriority.medium]!.toInt();
    final mediumFeeInSats =
        (gdkTransaction.transactionVsize! * mediumFeeRate).toInt();
    final mediumFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), mediumFeeInSats)));

    final lowFeeRate = rates[TransactionPriority.low]!.toInt();
    final lowFeeInSats =
        (gdkTransaction.transactionVsize! * lowFeeRate).toInt();
    final lowFeeInFiat =
        ref.watch(conversionProvider((Asset.btc(), lowFeeInSats)));

    selectedPriority.addListener(() {
      double feeRate;
      switch (selectedPriority.value) {
        case TransactionPriority.high:
          feeRate = highFeeRate * 1000;
        case TransactionPriority.medium:
          feeRate = mediumFeeRate * 1000;
        case TransactionPriority.low:
          feeRate = lowFeeRate * 1000;
      }

      onFeeRateChange(feeRate.toInt());
    });

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
                          label: AppLocalizations.of(context)!
                              .sendAssetReviewScreenConfirmPriorityHigh,
                          fee: highFeeInFiat ?? '',
                          satsPerByte:
                              highFeeRate != null ? highFeeRate.toInt() : 0,
                          isSelected: selectedPriority.value ==
                              TransactionPriority.high,
                          onPressed: () =>
                              selectedPriority.value = TransactionPriority.high,
                        ),
                      ),
                      SizedBox(
                        width: 10.w,
                      ),
                      Expanded(
                          child: _SelectionItem(
                        label: AppLocalizations.of(context)!
                            .sendAssetReviewScreenConfirmPriorityStandard,
                        fee: mediumFeeInFiat ?? '',
                        satsPerByte:
                            mediumFeeRate != null ? mediumFeeRate.toInt() : 0,
                        isSelected: selectedPriority.value ==
                            TransactionPriority.medium,
                        onPressed: () =>
                            selectedPriority.value = TransactionPriority.medium,
                      )),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _SelectionItem(
                        label: AppLocalizations.of(context)!
                            .sendAssetReviewScreenConfirmPriorityLow,
                        fee: lowFeeInFiat ?? '',
                        satsPerByte:
                            lowFeeRate != null ? lowFeeRate.toInt() : 0,
                        isSelected:
                            selectedPriority.value == TransactionPriority.low,
                        onPressed: () =>
                            selectedPriority.value = TransactionPriority.low,
                      )),
                      SizedBox(
                        width: 10.w,
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 100.h,
                        ),
                      ),
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
          height: 100.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
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
                AppLocalizations.of(context)!
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
                  AppLocalizations.of(context)!
                      .sendAssetReviewScreenConfirmPriorityTitle,
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
