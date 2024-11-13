import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/fee_estimate_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/exchange_rate/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

const liquidUnit = FeeAsset.lbtc;
const usdUnit = FeeAsset.tetherUsdt;

class LiquidTransactionFeeSelector extends HookConsumerWidget {
  const LiquidTransactionFeeSelector({
    required this.asset,
    required this.transaction,
    required this.isSendAll,
    super.key,
  });

  final Asset asset;
  final SendAssetOnchainTx? transaction;
  final bool isSendAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState<bool>(true);
    final usdtFeeSelected = useState<bool>(asset.isAnyUsdt);

    final liquidFeeRatePerVb = ref.watch(liquidFeeRateProvider).asData?.value;
    final liquidFeeRatePerKb =
        liquidFeeRatePerVb != null ? (liquidFeeRatePerVb * 1000).toInt() : 0;

    useEffect(() {
      usdtFeeSelected.addListener(() {
        Future.microtask(() {
          ref.watch(userSelectedFeeAssetProvider.notifier).state =
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

    // lbtc fee
    final lbtcFee = gdkTransaction?.fee;
    final lbtcAsset = ref.read(manageAssetsProvider).lbtcAsset;
    final hasEnoughFundsForLbtcFee = ref
            .watch(hasEnoughFundsForFeeProvider(
                asset: lbtcAsset, fee: (lbtcFee ?? 0).toDouble()))
            .asData
            ?.value ??
        true;

    // lbtc fee display
    final satsFee = useState<String?>(null);
    if (gdkTransaction?.fee != null && satsFee.value == null) {
      satsFee.value = gdkTransaction?.fee.toString();
    }
    final satsFeeDisplay =
        satsFee.value != null ? "${satsFee.value} Sats" : "Sats";

    // lbtc fee in fiat
    final referenceCurrency = ref.read(prefsProvider).referenceCurrency;
    final fiatRates = ref.watch(fiatRatesProvider).asData?.value;
    final rate = fiatRates
        ?.firstWhere((element) => element.code == (referenceCurrency))
        .rate;
    final amountFiat = lbtcFee != null && rate != null
        ? (lbtcFee / (satsPerBtc / rate)).toStringAsFixed(2)
        : '';
    final lbtcFeeInFiatDisplay = "$referenceCurrency $amountFiat";

    // usdt fee estimate & display
    final enteredAmount = ref.read(userEnteredAmountProvider);
    final sendAmount = ref.read(
        enteredAmountWithPrecisionProvider(enteredAmount ?? Decimal.zero));
    final sendAll = ref.read(useAllFundsProvider);
    final isUsdtAssetEnabled = ref.read(manageAssetsProvider).isUsdtEnabled;
    // TODO: isLowball hardcoded true but need to refactor to read from state if lowball fails and we fallback to higher fees
    final taxiFeeEstimate = ref
        .watch(estimatedTaxiFeeUsdtProvider((sendAmount, sendAll, true)))
        .asData
        ?.value;
    final taxiFeeDisplay = taxiFeeEstimate != null
        ? '~${ref.read(formatterProvider).formatAssetAmountDirect(
              amount: taxiFeeEstimate.toInt(),
              precision:
                  ref.read(manageAssetsProvider).liquidUsdtAsset.precision,
              roundingOverride: kUsdtDisplayPrecision,
              removeTrailingZeros: false,
            )} USDt'
        : "";
    final hasEnoughFundsForUsdtFee = ref
            .watch(hasEnoughFundsForFeeProvider(
                asset: ref.read(manageAssetsProvider).liquidUsdtAsset,
                fee: (taxiFeeEstimate ?? 0).toDouble()))
            .asData
            ?.value ??
        true;

    // usdt fee enabled
    final taxiDisabled = ref.watch(sideswapTaxiProvider).hasError;
    if (taxiDisabled) {
      usdtFeeSelected.value = false;
    }
    final usdtFeeEnabled = asset.isAnyUsdt &&
        !taxiDisabled &&
        isUsdtAssetEnabled &&
        hasEnoughFundsForUsdtFee;

    // toggle automatically if one of the assets doesn't have enough funds and the other doesn't
    // if both don't have enough funds, will show error message below
    if (!hasEnoughFundsForLbtcFee && hasEnoughFundsForUsdtFee) {
      usdtFeeSelected.value = true;
    } else if (!hasEnoughFundsForUsdtFee && hasEnoughFundsForLbtcFee) {
      usdtFeeSelected.value = false;
    }

    final onSelectionPressed = useCallback((bool isUsdtSelected) {
      if (isUsdtSelected && hasEnoughFundsForUsdtFee) {
        usdtFeeSelected.value = true;
      } else if (!isUsdtSelected && hasEnoughFundsForLbtcFee) {
        usdtFeeSelected.value = false;
      }
    }, [hasEnoughFundsForUsdtFee, hasEnoughFundsForLbtcFee, usdtFeeSelected]);

    logger.d(
        "[Send][Fee] liquid fee selector - hasEnoughFundsForLbtcFee: $hasEnoughFundsForLbtcFee - hasEnoughFundsForUsdtFee: $hasEnoughFundsForUsdtFee");

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
                          ? Svgs.liquidAsset
                          : Svgs.l2AssetDisabled,
                      fee: satsFeeDisplay,
                      feeInFiat: lbtcFeeInFiatDisplay,
                      satsPerByte: (liquidFeeRatePerKb / 1000),
                      feeUnit: liquidUnit.name,
                      isSelected:
                          hasEnoughFundsForLbtcFee && !usdtFeeSelected.value,
                      isEnabled: hasEnoughFundsForLbtcFee,
                      onPressed: () => onSelectionPressed(false),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  //ANCHOR: Usdt fee selector
                  Expanded(
                    child: _SelectionItem(
                      label: context.loc.sendAssetReviewScreenConfirmFeeTether,
                      svgIcon: hasEnoughFundsForUsdtFee && usdtFeeEnabled
                          ? Svgs.usdtAsset
                          : Svgs.usdtAssetDisabled,
                      fee: usdtFeeEnabled ? taxiFeeDisplay : "",
                      feeInFiat: null,
                      feeUnit: usdUnit.name,
                      satsPerByte: (liquidFeeRatePerKb / 1000),
                      hideFiatConversion: true,
                      isSelected:
                          hasEnoughFundsForUsdtFee && usdtFeeSelected.value,
                      isEnabled: usdtFeeEnabled,
                      onPressed: () => onSelectionPressed(true),
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

class _SelectionItem extends HookConsumerWidget {
  const _SelectionItem({
    required this.label,
    required this.svgIcon,
    required this.fee,
    required this.feeInFiat,
    required this.satsPerByte,
    required this.feeUnit,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
    this.hideFiatConversion = false,
  });

  final String svgIcon;
  final String label;
  final String? fee;
  final String? feeInFiat;
  final double satsPerByte;
  final String feeUnit;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;
  final bool hideFiatConversion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    final textColor = useMemoized(
      () {
        if (isSelected && isEnabled) {
          return Theme.of(context).colors.sendAssetPrioritySelectedText;
        }
        if (isEnabled) {
          return isDarkMode ? Colors.grey : Colors.black;
        }
        return Colors.grey;
      },
      [isDarkMode, isSelected, isEnabled],
    );

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : isDarkMode
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6.r),
        child: Ink(
          height: 160.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colors.sendAssetPriorityUnselectedBorder,
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
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
              ),
              Text(
                '$fee',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
              ),
              if (!hideFiatConversion && feeInFiat != null) ...[
                Text(
                  feeInFiat!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                ),
              ] else ...[
                SizedBox(height: 16.h),
              ]
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
