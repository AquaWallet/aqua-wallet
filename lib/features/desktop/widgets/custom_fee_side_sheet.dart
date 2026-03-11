import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/data/data.dart';

class CustomFeeSideSheet extends HookConsumerWidget {
  const CustomFeeSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.args,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final CustomFeeInputScreenArguments args;

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
        Navigator.pop(context);
      });
    }, [feeAmount, customRateSatsPerVByte]);

    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.send,
      showBackButton: false,
      widgetAtBottom: AquaButton.primary(
        onPressed: isBelowMinimum ? null : onFeeConfirm,
        text: loc.confirm,
      ),
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 120,
                  maxWidth: double.infinity,
                ),
                child: TextField(
                  controller: controller,
                  style: AquaTypography.h3SemiBold,
                  autofocus: true,
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
                      text: loc.satsPerVByte(''),
                      color: aquaColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AquaText.body1Medium(
              text: '~ $feeInFiat',
              color: aquaColors.textSecondary,
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AquaText.body2SemiBold(
                  text: loc.min,
                  color: isError
                      ? aquaColors.accentDanger
                      : aquaColors.textTertiary,
                ),
                const SizedBox(width: 4),
                AquaText.body2SemiBold(
                  text: loc.satsPerVByte(2),
                  color: isError
                      ? aquaColors.accentDanger
                      : aquaColors.textPrimary,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required CustomFeeInputScreenArguments args,
  }) {
    return SideSheet.right(
      body: CustomFeeSideSheet(
        aquaColors: aquaColors,
        loc: loc,
        args: args,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
