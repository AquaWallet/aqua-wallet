import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final kAllowedInputRegex = RegExp(r'^\d*');

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
    final inputProvider = useMemoized(
      () => sendAssetInputStateProvider(arguments),
    );
    final selectedFee = ref.watch(inputProvider).value?.fee?.mapOrNull(
          bitcoin: (e) => e.fee is BitcoinFeeModelCustom
              ? e.fee as BitcoinFeeModelCustom
              : null,
        );
    final isCustomFeeSelected = useMemoized(
      () => selectedFee != null,
      [selectedFee],
    );
    final txnState = ref.watch(sendAssetTxnProvider(arguments)).value;
    final txnVsize = useMemoized(
      () => txnState?.whenOrNull(
        created: (e) => e.mapOrNull(gdkTx: (t) => t.gdkTx.transactionVsize),
      ),
      [txnState],
    );

    final showCustomFeeInputSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        builder: (_) => CustomBitcoinFeeInputSheet(
          title: context.loc.setCustomFeeAmount,
          minFeeRate: minFeeRateOption!.feeRate,
          transactionVsize: txnVsize!,
          onConfirm: (fee) => ref
              .read(inputProvider.notifier)
              .updateFeeAsset(fee.toFeeOptionModel()),
        ),
      );
    }, [minFeeRateOption]);

    return Material(
      color: isCustomFeeSelected
          ? context.colors.selectedFeeCard
          : context.colors.altScreenSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(
          color: isCustomFeeSelected
              ? context.colors.sendAssetPrioritySelectedBorder
              : Colors.transparent,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCustomFeeSelected ? 16.0 : 0),
        child: Row(
          mainAxisAlignment: isCustomFeeSelected
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          children: [
            if (isCustomFeeSelected) ...{
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$ ${selectedFee!.feeFiat.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: context.colors.sendAssetPrioritySelectedText,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    context.loc.satsPerVbyte(selectedFee.feeRate.toInt()),
                    style: TextStyle(
                      color: context.colors.sendAssetPrioritySelectedText,
                    ),
                  ),
                ],
              ),
            },
            _CustomFeeButton(
              isEnabled: minFeeRateOption != null && txnVsize != null,
              isSelected: isCustomFeeSelected,
              onTap: showCustomFeeInputSheet,
            )
          ],
        ),
      ),
    );
  }
}

class _CustomFeeButton extends StatelessWidget {
  const _CustomFeeButton({
    required this.onTap,
    required this.isSelected,
    required this.isEnabled,
  });

  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.altScreenSurface,
      borderRadius: BorderRadius.circular(6.0),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(6.0),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                )
              : BoxDecoration(
                  border: Border.all(
                    color: context.colors.sendAssetPriorityUnselectedBorder,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                ),
          child: Text(
            context.loc.sendAssetReviewScreenConfirmCustomFeeButton,
            style: TextStyle(
              color: isSelected
                  ? context.colors.sendAssetPrioritySelectedText
                  : context.colors.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomBitcoinFeeInputSheet extends HookConsumerWidget {
  const CustomBitcoinFeeInputSheet({
    super.key,
    required this.title,
    required this.minFeeRate,
    required this.transactionVsize,
    required this.onConfirm,
  });

  final String title;
  final int transactionVsize;
  final double minFeeRate;
  final Function(BitcoinFeeModelCustom fee) onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final textUpdates = useListenable(controller);
    final customRateSatsPerVByte = useMemoized(() {
      return int.tryParse(controller.text) ?? 0;
    }, [textUpdates.text]);
    final feeAmount = useMemoized(() {
      return customRateSatsPerVByte * transactionVsize;
    }, [customRateSatsPerVByte, transactionVsize]);
    final feeInFiat =
        ref.watch(satsToFiatDisplayWithSymbolProvider(feeAmount)).value;
    final isBelowMinimum = useMemoized(() {
      return minFeeRate > customRateSatsPerVByte;
    }, [minFeeRate, customRateSatsPerVByte]);

    final onFeeConfirm = useCallback(() async {
      final feeFiat = await ref.read(fiatProvider).getSatsToFiat(feeAmount);
      onConfirm(BitcoinFeeModelCustom(
        feeSats: (kVbPerKb * customRateSatsPerVByte).toInt(),
        feeFiat: feeFiat.toDouble(),
        feeRate: customRateSatsPerVByte.toDouble(),
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
    }, [customRateSatsPerVByte, isBelowMinimum]);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 21.0),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 18.0),
            //ANCHOR - Title
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 19.0),
            //ANCHOR - Amount Input
            Container(
              decoration: Theme.of(context).solidBorderDecoration,
              child: TextField(
                controller: controller,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 24.0,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(kAllowedInputRegex),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.replaceAll(',', '.'),
                    ),
                  ),
                ],
                decoration: Theme.of(context).inputDecoration.copyWith(
                      hintText: context.loc.setAmount,
                      hintStyle: context.textTheme.titleLarge?.copyWith(
                        color: context.colors.hintTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 24.0,
                      ),
                      border: Theme.of(context).inputBorder,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'sats/vbyte',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontSize: 24.0,
                            ),
                          ),
                          const SizedBox(width: 23.0),
                        ],
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //ANCHOR - Fiat Fee
                Text(
                  feeInFiat != null ? "≈ $feeInFiat" : '',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontSize: 18.0,
                  ),
                ),
                if (isBelowMinimum) ...{
                  //ANCHOR - Minimum Fee Error
                  Text(
                    context.loc.sendAssetReviewScreenConfirmCustomFeeMinimum(
                        minFeeRate.toInt()),
                    style: context.textTheme.titleSmall?.copyWith(
                      fontSize: 18.0,
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                },
              ],
            ),
            const SizedBox(height: 24.0),
            //ANCHOR - Confirm Button
            SizedBox(
              width: double.maxFinite,
              child: AquaElevatedButton(
                onPressed: customRateSatsPerVByte > 0 && !isBelowMinimum
                    ? onFeeConfirm
                    : null,
                child: Text(context.loc.confirm),
              ),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
