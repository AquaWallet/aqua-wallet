import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class CustomFeeButton extends HookConsumerWidget {
  const CustomFeeButton({
    required this.aquaColors,
    required this.loc,
    required this.args,
    this.alignment = Alignment.centerRight,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final CustomFeeInputScreenArguments args;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final provider =
    //     useMemoized(() => sendAssetInputStateProvider(args.sendArgs));

    ///TODO: Provider was commented because in testing it breaks UI when it cant get data
    const selectedFee = null;
    // ref.watch(provider).value?.fee?.mapOrNull(
    //       bitcoin: (e) => e.fee is BitcoinFeeModelCustom
    //           ? e.fee as BitcoinFeeModelCustom
    //           : null,
    //     );
    final txnState = ref.watch(sendAssetTxnProvider(args.sendArgs)).value;
    final txnVsize = useMemoized(
      () => txnState?.whenOrNull(
        created: (e) => e.mapOrNull(gdkTx: (t) => t.gdkTx.transactionVsize),
      ),
      [txnState],
    );

    final onCustomFeeTap = useMemoized(() {
      return args.minFeeRateOption != null &&

              ///TODO: default true for testing UI shoud be removed when provider is ready
              true
          // txnVsize != null
          ? () => CustomFeeSideSheet.show(
                context: context,
                aquaColors: aquaColors,
                loc: loc,
                args: args,
              )
          : null;
    }, [args.minFeeRateOption, txnVsize]);

    return Align(
      alignment: alignment,
      child: selectedFee == null
          ? AquaButton.utility(
              text: loc.sendAssetReviewScreenConfirmCustomFeeButton,
              onPressed: onCustomFeeTap,
            )
          : AquaListItem(
              title: loc.sendAssetReviewScreenConfirmCustomFeeButton,
              iconLeading: AquaRadio.small(
                value: true,
                groupValue: true,
                colors: context.aquaColors,
              ),
              subtitleTrailing:
                  loc.satsPerVByte(selectedFee?.feeRate.toInt() ?? '0'),
              subtitleTrailingColor: aquaColors.textSecondary,
              iconTrailing: AquaIcon.chevronRight(
                size: 18,
                color: aquaColors.textSecondary,
              ),
              onTap: onCustomFeeTap,
            ),
    );
  }
}
