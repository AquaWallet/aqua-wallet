import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class CustomBitcoinFeeInput extends HookConsumerWidget {
  const CustomBitcoinFeeInput({
    super.key,
    required this.minFeeRateOption,
    required this.arguments,
  });

  final SendAssetArguments arguments;
  final BitcoinFeeModelMin? minFeeRateOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = useMemoized(() => sendAssetInputStateProvider(arguments));
    final selectedFee = ref.watch(provider).value?.fee?.mapOrNull(
          bitcoin: (e) => e.fee is BitcoinFeeModelCustom
              ? e.fee as BitcoinFeeModelCustom
              : null,
        );
    final txnState = ref.watch(sendAssetTxnProvider(arguments)).value;
    final txnVsize = useMemoized(
      () => txnState?.whenOrNull(
        created: (e) => e.mapOrNull(gdkTx: (t) => t.gdkTx.transactionVsize),
      ),
      [txnState],
    );

    final onCustomFeeTap = useMemoized(() {
      return minFeeRateOption != null && txnVsize != null
          ? () => context.push(
                CustomFeeInputScreen.routeName,
                extra: CustomFeeInputScreenArguments(
                  sendArgs: arguments,
                  minFeeRateOption: minFeeRateOption,
                ),
              )
          : null;
    }, [minFeeRateOption, txnVsize]);

    return selectedFee == null
        ? _CustomFeeButton(onTap: onCustomFeeTap)
        : _CustomFeeCard(
            selectedFee: selectedFee,
            onTap: onCustomFeeTap,
          );
  }
}

class _CustomFeeButton extends StatelessWidget {
  const _CustomFeeButton({
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AquaButton.utility(
        onPressed: onTap,
        text: context.loc.sendAssetReviewScreenConfirmCustomFeeButton,
      ),
    );
  }
}

class _CustomFeeCard extends StatelessWidget {
  const _CustomFeeCard({
    required this.onTap,
    required this.selectedFee,
  });

  final VoidCallback? onTap;
  final BitcoinFeeModelCustom selectedFee;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AquaListItem(
        onTap: onTap,
        iconLeading: AquaRadio.small(
          value: true,
          groupValue: true,
          colors: context.aquaColors,
        ),
        title: context.loc.sendAssetReviewScreenConfirmCustomFeeButton,
        titleTrailing: context.loc.satsPerVByte(selectedFee.feeRate),
        iconTrailing: AquaIcon.chevronRight(
          size: 18,
          color: context.aquaColors.textPrimary,
        ),
        colors: context.aquaColors,
      ),
    );
  }
}
