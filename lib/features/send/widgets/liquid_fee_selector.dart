import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class LiquidFeeSelector extends HookConsumerWidget {
  const LiquidFeeSelector({
    super.key,
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final isExpanded = useState<bool>(false);

    final feeOptionsProvider = useMemoized(
      () => sendAssetFeeOptionsProvider(args),
      [args],
    );
    final feeOptionsAsync = ref.watch(feeOptionsProvider);
    final isFeeOptionsLoading = useMemoized(
      () => feeOptionsAsync.isLoading,
      [feeOptionsAsync],
    );
    final feeOptions = useMemoized(
      () => feeOptionsAsync.asData?.value ?? [],
      [feeOptionsAsync],
    );
    final lbtcFeeOption = useMemoized(
      () => feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .map((e) => e.fee)
          .whereType<LbtcLiquidFeeModel>()
          .firstOrNull,
      [feeOptions],
    );
    final usdtFeeOption = useMemoized(
      () => feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .map((e) => e.fee)
          .whereType<UsdtLiquidFeeModel>()
          .firstOrNull,
      [feeOptions],
    );
    final canPayLbtcFee = useMemoized(
      () => lbtcFeeOption?.availableForFeePayment ?? false,
      [lbtcFeeOption],
    );
    final canPayUsdtFee = useMemoized(
      () => usdtFeeOption?.availableForFeePayment ?? false,
      [usdtFeeOption],
    );
    final inputProvider = useMemoized(
      () => sendAssetInputStateProvider(args),
    );
    final input = ref.watch(inputProvider).value!;

    // Automatically enable an available fee option
    useEffect(() {
      if (input.fee != null) return null;
      //NOTE: Last because we want to prioritize USDt over L-BTC for USDt send
      final availableFeeOption = feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .where((e) => e.fee.isEnabled)
          .lastWhereOrNull((e) => e.fee.availableForFeePayment);

      if (availableFeeOption != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(inputProvider.notifier).updateFeeAsset(availableFeeOption);
          // Expand the selector once the fee options are loaded and selected
          isExpanded.value = true;
        });
      }

      return null;
    }, [feeOptions]);

    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isFeeOptionsLoading && !canPayLbtcFee && !canPayUsdtFee) ...[
            //ANCHOR: Not enough funds error
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 30.0,
              ),
              decoration: BoxDecoration(
                color: context.colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.loc.insufficientBalanceToCoverFees,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      color: context.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            //ANCHOR: Lbtc or Usdt fee selector
            ExpandablePanelHeader(
              isExpanded: isExpanded,
              state: feeOptionsAsync,
              title: context.loc.sendAssetReviewScreenConfirmFeeTitle,
            ),
          ],
          feeOptionsAsync.maybeWhen(
            error: (error, _) => Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              child: ErrorLabel(
                text: error is ExceptionLocalized
                    ? error.toLocalizedString(context)
                    : context.loc.errorWhilePreparingFeeOptions,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          if (isExpanded.value) ...[
            Container(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              decoration: BoxDecoration(
                color: context.colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //ANCHOR: Lbtc fee selector
                  if (lbtcFeeOption != null) ...{
                    Expanded(
                      child: _SelectionItem(
                        label: context.loc.layer2Bitcoin,
                        svgIcon: lbtcFeeOption.isEnabled
                            ? Svgs.layerTwoSingle
                            : Svgs.l2AssetDisabled,
                        fee: "${lbtcFeeOption.feeSats} Sats",
                        feeInFiat: lbtcFeeOption.fiatFeeDisplay,
                        feeUnit: lbtcFeeOption.feeAsset.name,
                        isEnabled: lbtcFeeOption.isEnabled,
                        isSelected: input.isLiquidFeeAsset,
                        onPressed: () => ref
                            .read(inputProvider.notifier)
                            .updateFeeAsset(lbtcFeeOption.toFeeOptionModel()),
                      ),
                    ),
                  },
                  if (usdtFeeOption != null) ...{
                    const SizedBox(width: 16.0),
                    //ANCHOR: Usdt fee selector
                    Expanded(
                      child: _SelectionItem(
                        label:
                            context.loc.sendAssetReviewScreenConfirmFeeTether,
                        svgIcon: usdtFeeOption.isEnabled
                            ? Svgs.usdtAsset
                            : Svgs.usdtAssetDisabled,
                        fee: usdtFeeOption.isEnabled
                            ? usdtFeeOption.feeDisplay
                            : '',
                        feeInFiat: null,
                        feeUnit: usdtFeeOption.feeAsset.name,
                        hideFiatConversion: true,
                        isEnabled: usdtFeeOption.isEnabled,
                        isSelected: input.isUsdtFeeAsset,
                        onPressed: () => ref
                            .read(inputProvider.notifier)
                            .updateFeeAsset(usdtFeeOption.toFeeOptionModel()),
                      ),
                    ),
                  },
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
          return context.colors.sendAssetPrioritySelectedText;
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
          ? context.colors.selectedFeeCard
          : context.colors.unselectedFeeCard,
      borderRadius: BorderRadius.circular(6.0),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6.0),
        child: Ink(
          height: 160.0,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    width: 2,
                    color: context.colors.sendAssetPrioritySelectedBorder,
                  ),
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    width: 2,
                    color: context.colors.sendAssetPriorityUnselectedBorder,
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                svgIcon,
                width: 42.0,
                height: 42.0,
              ),
              const Spacer(),
              Text(
                label,
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                '$fee',
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (!hideFiatConversion && feeInFiat != null) ...[
                Text(
                  '≈ ${feeInFiat!}',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16.0),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
