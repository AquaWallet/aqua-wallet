import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class AssetAmountLimitsDisplay extends ConsumerWidget {
  const AssetAmountLimitsDisplay({
    super.key,
    required this.args,
    required this.minLimitSats,
    required this.maxLimitSats,
  })  : _minLimit = null,
        _maxLimit = null;

  const AssetAmountLimitsDisplay.static({
    super.key,
    required String minLimit,
    required String maxLimit,
  })  : args = null,
        minLimitSats = null,
        maxLimitSats = null,
        _minLimit = minLimit,
        _maxLimit = maxLimit;

  final ReceiveAmountArguments? args;
  final int? minLimitSats;
  final int? maxLimitSats;
  final String? _minLimit;
  final String? _maxLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? minLimit = _minLimit;
    String? maxLimit = _maxLimit;

    if (args != null && minLimitSats != null && maxLimitSats != null) {
      final formatter = ref.read(formatProvider);
      final inputState =
          ref.watch(receiveAssetInputStateProvider(args!)).valueOrNull;
      final currentUnit = inputState != null
          ? SupportedDisplayUnits.fromAssetInputUnit(inputState.cryptoUnit)
          : ref.watch(displayUnitsProvider).currentDisplayUnit;
      final currencyUnit = currentUnit.value.toLowerCase();

      final minFormatted = formatter.formatAssetAmount(
        amount: minLimitSats!,
        asset: args!.asset,
        displayUnitOverride: currentUnit,
      );
      final maxFormatted = formatter.formatAssetAmount(
        amount: maxLimitSats!,
        asset: args!.asset,
        displayUnitOverride: currentUnit,
      );
      minLimit = '$minFormatted $currencyUnit';
      maxLimit = '$maxFormatted $currencyUnit';
    }

    return Skeletonizer(
      enabled: minLimit == null || maxLimit == null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.body2Medium(
                text: context.loc.minLabel,
                color: context.aquaColors.textSecondary,
              ),
              const SizedBox(width: 4),
              AquaText.body2Medium(
                text: minLimit ?? '',
                color: context.aquaColors.textSecondary,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.body2Medium(
                text: context.loc.maxLabel,
                color: context.aquaColors.textSecondary,
              ),
              const SizedBox(width: 4),
              AquaText.body2Medium(
                text: maxLimit ?? '',
                color: context.aquaColors.textSecondary,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
