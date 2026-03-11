import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class CustomFeeInputScreenArguments {
  final SendAssetArguments sendArgs;
  final BitcoinFeeModelMin? minFeeRateOption;

  CustomFeeInputScreenArguments({
    required this.sendArgs,
    required this.minFeeRateOption,
  });
}

class CustomFeeInputScreen extends HookConsumerWidget {
  const CustomFeeInputScreen({
    super.key,
    required this.args,
  });

  final CustomFeeInputScreenArguments args;

  static const routeName = '/customFeeInput';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final textUpdates = useListenable(controller);
    final customRateSatsPerVByte = useMemoized(
      () => int.tryParse(controller.text) ?? 0,
      [textUpdates.text],
    );

    final txnState = ref.watch(sendAssetTxnProvider(args.sendArgs)).value;
    final transactionVsize = useMemoized(() {
      final vSize = txnState?.whenOrNull(
        created: (e) => e.mapOrNull(gdkTx: (t) => t.gdkTx.transactionVsize),
      );
      return vSize ?? 0;
    }, [txnState]);
    final feeAmount = useMemoized(
      () => customRateSatsPerVByte * transactionVsize,
      [customRateSatsPerVByte, transactionVsize],
    );
    final feeInFiat =
        ref.watch(satsToFiatDisplayWithSymbolProvider(feeAmount)).value;
    final minFeeRate = args.minFeeRateOption!.feeRate;
    final isBelowMinimum = useMemoized(
      () => minFeeRate > customRateSatsPerVByte,
      [minFeeRate, customRateSatsPerVByte],
    );
    final isError = useMemoized(
      () => textUpdates.text.isNotEmpty && isBelowMinimum,
      [isBelowMinimum, textUpdates.text],
    );

    final onFeeConfirm = useCallback(() async {
      final feeFiat = await ref.read(fiatProvider).getSatsToFiat(feeAmount);
      final fee = BitcoinFeeModelCustom(
        feeSats: (kVbPerKb * customRateSatsPerVByte).toInt(),
        feeFiat: feeFiat.toDouble(),
        feeRate: customRateSatsPerVByte.toDouble(),
      );
      ref
          .read(sendAssetInputStateProvider(args.sendArgs).notifier)
          .updateFeeAsset(fee.toFeeOptionModel());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
      });
    }, [feeAmount, customRateSatsPerVByte]);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.sendAssetReviewScreenConfirmCustomFeeButton,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    //ANCHOR - Amount Input Field
                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: double.infinity,
                        ),
                        child: TextField(
                          controller: controller,
                          style: AquaTypography.h3SemiBold,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            hintText: '0',
                            hintStyle: AquaTypography.h3SemiBold,
                            isCollapsed: true,
                            isDense: true,
                            suffixIcon: AquaText.h3SemiBold(
                              text: context.loc.satsPerVByte(''),
                              color: context.aquaColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    //ANCHOR - Fiat Fee
                    AquaText.body1Medium(
                      text: '~ $feeInFiat',
                      color: context.aquaColors.textSecondary,
                    ),
                  ],
                ),
              ),
              //ANCHOR - Minimum Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AquaText.body2SemiBold(
                    text: context.loc.min,
                    color: isError
                        ? context.aquaColors.accentDanger
                        : context.aquaColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  AquaText.body2SemiBold(
                    text: context.loc.satsPerVByte(minFeeRate),
                    color: isError
                        ? context.aquaColors.accentDanger
                        : context.aquaColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              //ANCHOR - Numpad
              AquaNumpad(
                decimalAllowed: false,
                onKeyPressed: controller.addKey,
                colors: context.aquaColors,
              ),
              const SizedBox(height: 16),
              //ANCHOR - Confirm Button
              AquaButton.primary(
                text: context.loc.confirm,
                onPressed: isBelowMinimum ? null : onFeeConfirm,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
