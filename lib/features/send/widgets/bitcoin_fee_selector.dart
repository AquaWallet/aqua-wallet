import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BitcoinFeeSelector extends HookConsumerWidget
    with FeeOptionsErrorHandlerMixin {
  const BitcoinFeeSelector({
    super.key,
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      if (feeOptions.isNotEmpty && selectedFeeOption == null ||
          !feeOptions.contains(selectedFeeOption)) {
        // Select the first fee option by default
        WidgetsBinding.instance.addPostFrameCallback((_) => ref
            .read(inputProvider.notifier)
            .updateFeeAsset(feeOptions.first.toFeeOptionModel()));
      }
      return null;
    }, [feeOptions.length]);

    setupFeeOptionsErrorHandler(context, ref, feeOptionsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
        if (!feeOptionsAsync.hasError) ...[
          const SizedBox(height: 16),
          //ANCHOR - Custom Fee
          CustomBitcoinFeeInput(
            arguments: args,
            minFeeRateOption: minFeeRateOption,
          ),
        ],
      ],
    );
  }
}

class _SelectionItem extends ConsumerWidget {
  const _SelectionItem({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final BitcoinFeeModel item;
  final bool isSelected;
  final void Function(BitcoinFeeModel fee) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AquaCard.surface(
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: AquaFeeTile(
        title: item.label(context),
        amountCrypto: context.loc.satsPerVByte(item.feeRateDisplay),
        amountFiat: item.feeFiatDisplay,
        colors: context.aquaColors,
        isSelected: isSelected,
        onTap: () => onPressed(item),
      ),
    );
  }
}
