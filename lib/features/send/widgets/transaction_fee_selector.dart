import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/send/providers/send_asset_fee_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import 'package:aqua/data/provider/conversion_provider.dart';

const liquidFeeRate = 100; // hardcoded sats per 1000vbytes
const usdFee = 0.01;
const liquidUnit = FeeAsset.lbtc;
const usdUnit = FeeAsset.tetherUsdt;

class UsdtTransactionFeeSelector extends HookConsumerWidget {
  const UsdtTransactionFeeSelector({
    required this.asset,
    required this.gdkTransaction,
    super.key,
  });

  final Asset asset;
  final GdkNewTransactionReply? gdkTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState<bool>(true);
    final isUsdtPayment = useState<bool>(false);

    isUsdtPayment.addListener(() {
      ref.read(selectedFeeAssetProvider.notifier).state =
          isUsdtPayment.value ? usdUnit : liquidUnit;
      logger.d('[TAXI] fee selector toggled - isUsd: ${isUsdtPayment.value}');
    });

    final hasEnoughFundsForLbtcFee = (gdkTransaction != null);

    final hasEnoughFundsForUsdtFee = ref
            .watch(hasEnoughFundsForFeeProvider(
                asset: ref.read(manageAssetsProvider).liquidUsdtAsset,
                fee: pow(usdFee, asset.precision).toDouble()))
            .asData
            ?.value ??
        true;

    final feeInFiat = (gdkTransaction == null)
        ? ""
        : ref.watch(conversionProvider((Asset.btc(), gdkTransaction!.fee!)));
    // toggle automatically if one of the assets doesn't have enough funds and the other doesn't
    // if both don't have enough funds, will show error message below
    if (!hasEnoughFundsForLbtcFee && hasEnoughFundsForUsdtFee) {
      isUsdtPayment.value = true;
    } else if (!hasEnoughFundsForUsdtFee && hasEnoughFundsForLbtcFee) {
      isUsdtPayment.value = false;
    }

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //ANCHOR: Not enough funds error
          if (!hasEnoughFundsForUsdtFee && !hasEnoughFundsForLbtcFee) ...[
            Container(
              padding: EdgeInsets.only(
                  left: 20.w, right: 20.w, bottom: 30.h, top: 30.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .pegInsufficientFeeBalanceError,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ),
            ),
          ]
          //ANCHOR: Lbtc or Usdt fee selector
          else ...[
            _Header(isExpanded: isExpanded),
          ],
          if (isExpanded.value) ...[
            Container(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //ANCHOR: Lbtc fee selector
                  Expanded(
                    child: _SelectionItem(
                      label: AppLocalizations.of(context)!.layer2Bitcoin,
                      svgIcon: Svgs.l2Asset,
                      fee: feeInFiat,
                      satsPerByte: (liquidFeeRate / 1000),
                      feeUnit: liquidUnit.name,
                      isSelected: hasEnoughFundsForLbtcFee,
                      isEnabled: hasEnoughFundsForLbtcFee,
                      onPressed: () => hasEnoughFundsForLbtcFee
                          ? isUsdtPayment.value = false
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),

                  //ANCHOR: Usdt fee selector
                  Expanded(
                    child: _SelectionItem(
                      label: AppLocalizations.of(context)!
                          .sendAssetReviewScreenConfirmFeeTether,
                      svgIcon: Svgs.usdtAsset,
                      // fee: hasEnoughFundsForUsdtFee? usdFee.toString():"",
                      fee: hasEnoughFundsForUsdtFee ? "" : "",
                      feeUnit: usdUnit.name,
                      satsPerByte: (liquidFeeRate / 1000),
                      // isSelected:
                      //     hasEnoughFundsForUsdtFee && isUsdtPayment.value,
                      isSelected: false,
                      isEnabled: false,
                      onPressed: () => hasEnoughFundsForUsdtFee
                          ? isUsdtPayment.value = true
                          : null,
                    ),
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
    required this.svgIcon,
    required this.fee,
    required this.satsPerByte,
    required this.feeUnit,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
  });

  final String svgIcon;
  final String label;
  final String? fee;
  final double satsPerByte;
  final String feeUnit;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // final feeText = fee % 1 == 0 ? fee.toInt() : fee.toStringAsFixed(2);
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.background,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6.r),
        child: Ink(
          height: 140.h,
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
              SvgPicture.asset(
                svgIcon,
                width: 42.r,
                height: 42.r,
                colorFilter: isEnabled
                    ? null
                    : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              ),
              const Spacer(),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: isSelected && isEnabled
                          ? Theme.of(context)
                              .colors
                              .sendAssetPrioritySelectedText
                          : Colors.grey,
                    ),
              ),
              SizedBox(height: 5.h),
              Text(
                '$fee',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected && isEnabled
                          ? Theme.of(context)
                              .colors
                              .sendAssetPrioritySelectedText
                          : Colors.grey,
                    ),
              ),
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
                      .sendAssetReviewScreenConfirmFeeTitle,
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
