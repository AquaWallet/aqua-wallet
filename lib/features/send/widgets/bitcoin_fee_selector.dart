import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/exchange_rate/providers/providers.dart';
import 'package:coin_cz/features/settings/shared/providers/providers.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BitcoinFeeSelector extends HookConsumerWidget {
  const BitcoinFeeSelector({
    super.key,
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final isExpanded = useState<bool>(true);
    final inputProvider = useMemoized(
      () => sendAssetInputStateProvider(args),
    );
    final selectedFeeOption = ref.watch(inputProvider).value?.fee?.mapOrNull(
          bitcoin: (e) => e.fee,
        );
    final feeOptionsProvider = useMemoized(
      () => sendAssetFeeOptionsProvider(args),
      [args],
    );
    final feeOptionsAsync = ref.watch(feeOptionsProvider);
    final feeOptions = useMemoized(
      () => [
        ...?feeOptionsAsync.asData?.value
            .whereType<BitcoinSendAssetFeeOptionModel>()
            .map((e) => e.fee)
            // NOTE: Based on the current implementation in prod, we are only
            // offering high and medium priority fee options.
            .where(
                (e) => e is BitcoinFeeModelHigh || e is BitcoinFeeModelMedium)
      ],
      [feeOptionsAsync.hasValue],
    );
    final minFeeRateOption = useMemoized(
      () => feeOptionsAsync.asData?.value
          .whereType<BitcoinSendAssetFeeOptionModel>()
          .map((e) => e.fee)
          .whereType<BitcoinFeeModelMin>()
          .firstOrNull,
      [feeOptions],
    );

    useEffect(() {
      if (feeOptions.isNotEmpty && selectedFeeOption == null) {
        // Select the first fee option by default
        WidgetsBinding.instance.addPostFrameCallback((_) => ref
            .read(inputProvider.notifier)
            .updateFeeAsset(feeOptions.first.toFeeOptionModel()));
      }
      return null;
    }, [feeOptions.length]);

    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12),
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpandablePanelHeader(
            isExpanded: isExpanded,
            state: feeOptionsAsync,
            title: context.loc.sendAssetReviewScreenConfirmPriorityTitle,
          ),
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
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: context.colors.altScreenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    padding: EdgeInsets.zero,
                    itemCount: feeOptions.length,
                    itemBuilder: (_, index) {
                      final feeItem = feeOptions[index];
                      return _SelectionItem(
                        item: feeItem,
                        isSelected: selectedFeeOption == feeItem,
                        onPressed: (fee) => ref
                            .read(inputProvider.notifier)
                            .updateFeeAsset(fee.toFeeOptionModel()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  //ANCHOR - Custom Fee
                  CustomBitcoinFeeInput(
                    arguments: args,
                    minFeeRateOption: minFeeRateOption,
                  )
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _SelectionItem extends ConsumerWidget {
  const _SelectionItem(
      {required this.item, required this.isSelected, required this.onPressed});

  final BitcoinFeeModel item;
  final bool isSelected;
  final void Function(BitcoinFeeModel fee) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

    final symbol = exchangeRate.currency.symbol;
    return Material(
      color: isSelected
          ? context.colors.selectedFeeCard
          : context.colors.unselectedFeeCard,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => onPressed(item),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 14,
            left: 10,
            right: 10,
          ),
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
              // ANCHOR - Fee Priority
              Text(
                item.label(context),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? context.colors.sendAssetPrioritySelectedText
                      : context.colors.onBackground,
                ),
              ),
              const Spacer(),
              //ANCHOR - Fiat Fee
              Text(
                '$symbol ${item.feeFiat.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? context.colors.sendAssetPrioritySelectedText
                      : context.colors.onBackground,
                ),
              ),
              //ANCHOR - Fee Rate
              Text(
                context.loc.satsPerVbyte(item.feeRate.toInt()),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isSelected
                      ? context.colors.sendAssetPrioritySelectedText
                      : context.colors.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
