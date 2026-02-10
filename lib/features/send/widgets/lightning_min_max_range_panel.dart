import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LightningMinMaxRangePanel extends HookConsumerWidget {
  const LightningMinMaxRangePanel({
    super.key,
    required this.args,
    required this.constraints,
  });

  final SendAssetArguments args;
  final SendAssetAmountConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = Asset.lbtc();
    final input = ref.watch(sendAssetInputStateProvider(args)).valueOrNull;
    final isFiatInput = input?.isFiatAmountInput ?? false;

    final formatCryptoAmount = useCallback((int value) {
      final unit = input?.inputUnit ?? AquaAssetInputUnit.crypto;
      final displayUnit = SupportedDisplayUnits.fromAssetInputUnit(unit);
      final amount = ref.read(formatProvider).formatAssetAmount(
            amount: value,
            asset: asset,
            displayUnitOverride: displayUnit,
          );
      final assetTicker = asset.getDisplayTicker(displayUnit);
      return '$amount $assetTicker';
    }, [input]);

    final minCrypto = formatCryptoAmount(constraints.minSats);
    final maxCrypto = formatCryptoAmount(constraints.maxSats);
    final minFiat = ref
            .watch(satsToFiatDisplayWithSymbolProvider(constraints.minSats))
            .valueOrNull ??
        '';
    final maxFiat = ref
            .watch(satsToFiatDisplayWithSymbolProvider(constraints.maxSats))
            .valueOrNull ??
        '';

    return AquaText.caption1Medium(
      text: context.loc.amountRange(
        isFiatInput ? maxFiat : maxCrypto,
        isFiatInput ? minFiat : minCrypto,
      ),
    );
  }
}
