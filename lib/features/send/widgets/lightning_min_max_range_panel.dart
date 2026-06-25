import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LightningMinMaxRangePanel extends ConsumerWidget {
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
    final fiatRates = ref.watch(fiatRatesProvider).valueOrNull;
    final isFiatInput = input?.isFiatAmountInput ?? false;

    String cryptoLabel(int sats) {
      final unit = input?.cryptoUnit ?? AquaAssetInputUnit.crypto;
      final displayUnit = SupportedDisplayUnits.fromAssetInputUnit(unit);
      final amount = ref.read(formatProvider).formatAssetAmount(
            amount: sats,
            asset: asset,
            displayUnitOverride: displayUnit,
          );
      return '$amount ${asset.getDisplayTicker(displayUnit)}';
    }

    String fiatLabel(int sats) {
      final rate = input?.rate;
      if (rate == null || fiatRates == null) return '';
      final fiatRate = fiatRates
              .firstWhereOrNull((r) => r.code == rate.currency.value)
              ?.rate ??
          0;
      final btcAmount = sats / SupportedDisplayUnits.btc.satsPerUnit;
      final fiatValue = fiatRate != 0 ? btcAmount * fiatRate : 0.0;
      return ref.read(formatProvider).formatFiatAmount(
            amount: DecimalExt.fromDouble(fiatValue),
            specOverride: rate.currency.format,
            withSymbol: true,
          );
    }

    final maxStr = isFiatInput
        ? fiatLabel(constraints.maxSats)
        : cryptoLabel(constraints.maxSats);
    final minStr = isFiatInput
        ? fiatLabel(constraints.minSats)
        : cryptoLabel(constraints.minSats);

    return AquaText.caption1Medium(
      text: context.loc.amountRange(maxStr, minStr),
    );
  }
}
