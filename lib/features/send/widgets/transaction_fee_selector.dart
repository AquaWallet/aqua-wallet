import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

const usdFee = 0.01;
const liquidUnit = FeeAsset.lbtc;
const usdUnit = FeeAsset.tetherUsdt;

class UsdtTransactionFeeSelector extends HookConsumerWidget {
  const UsdtTransactionFeeSelector({
    required this.asset,
    required this.transaction,
    super.key,
  });

  final Asset asset;
  final SendAssetOnchainTx? transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState<bool>(true);
    final usdtFeeSelected = useState<bool>(false);

    useEffect(() {
      usdtFeeSelected.addListener(() {
        Future.microtask(() {
          ref.read(userSelectedFeeAssetProvider.notifier).state =
              usdtFeeSelected.value ? usdUnit : liquidUnit;
          logger.d(
              '[Send][Taxi] fee selector toggled - isUsd: ${usdtFeeSelected.value}');
        });
      });
      return null;
    }, []);

    final GdkNewTransactionReply? gdkTransaction = useMemoized(() {
      return transaction?.maybeMap(
        gdkTx: (tx) => tx.gdkTx,
        orElse: () => null,
      );
    }, [transaction]);

    final lbtcFee = ref.read(onchainFeeInSatsProvider);
    final hasEnoughFundsForLbtcFee = ref
            .watch(hasEnoughFundsForFeeProvider(
                asset: ref.read(manageAssetsProvider).lbtcAsset,
                fee: lbtcFee.toDouble()))
            .asData
            ?.value ??
        true;

    final hasEnoughFundsForUsdtFee = ref
            .watch(hasEnoughFundsForFeeProvider(
                asset: ref.read(manageAssetsProvider).liquidUsdtAsset,
                fee: pow(usdFee, asset.precision).toDouble()))
            .asData
            ?.value ??
        true;

    final feeInFiat = (gdkTransaction != null)
        ? ref.watch(conversionProvider((Asset.btc(), gdkTransaction.fee!)))
        : "";
    final feeInSats = "${gdkTransaction?.fee?.toString()} Sats";

    // toggle automatically if one of the assets doesn't have enough funds and the other doesn't
    // if both don't have enough funds, will show error message below
    if (!hasEnoughFundsForLbtcFee && hasEnoughFundsForUsdtFee) {
      usdtFeeSelected.value = true;
    } else if (!hasEnoughFundsForUsdtFee && hasEnoughFundsForLbtcFee) {
      usdtFeeSelected.value = false;
    }

    logger.d(
        "[Send][Fee] liquid fee selector - hasEnoughFundsForLbtcFee: $hasEnoughFundsForLbtcFee - hasEnoughFundsForUsdtFee: $hasEnoughFundsForUsdtFee");
    logger.d(
        "[Send][Fee] liquid fee selector - feeInFiat: $feeInFiat - feeInSats: $feeInSats");

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
                    context.loc.pegInsufficientFeeBalanceError,
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
                      label: context.loc.layer2Bitcoin,
                      svgIcon: hasEnoughFundsForLbtcFee
                          ? Svgs.l2Asset
                          : Svgs.l2AssetDisabled,
                      fee: feeInSats,
                      satsPerByte: (liquidFeeRatePerKb / 1000),
                      feeUnit: liquidUnit.name,
                      isSelected: hasEnoughFundsForLbtcFee,
                      isEnabled: hasEnoughFundsForLbtcFee,
                      onPressed: () => hasEnoughFundsForLbtcFee
                          ? usdtFeeSelected.value = false
                          : null,
                    ),
                  ),
                  SizedBox(width: 16.w),

                  //ANCHOR: Usdt fee selector
                  Expanded(
                    child: _SelectionItem(
                      label: context.loc.sendAssetReviewScreenConfirmFeeTether,
                      svgIcon: Svgs.usdtAssetDisabled,
                      fee: hasEnoughFundsForUsdtFee ? "" : "",
                      feeUnit: usdUnit.name,
                      satsPerByte: (liquidFeeRatePerKb / 1000),
                      // isSelected:
                      //     hasEnoughFundsForUsdtFee && isUsdtPayment.value,
                      isSelected: false,
                      isEnabled: false,
                      //TODO - Add a check to see if USDt is enabled
                      // isEnabled: ref.read(manageAssetsProvider).isUsdtEnabled,
                      onPressed: () => hasEnoughFundsForUsdtFee
                          ? usdtFeeSelected.value = true
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
          height: 160.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colors.sendAssetPriorityUnselectedBorder
                  : Colors.transparent,
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
              SizedBox(height: 8.h),
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
                  context.loc.sendAssetReviewScreenConfirmFeeTitle,
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
