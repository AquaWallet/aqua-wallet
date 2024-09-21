import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SideshiftMinMaxPanel extends HookConsumerWidget {
  final Asset asset;

  const SideshiftMinMaxPanel({
    required this.asset,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatAmount = useCallback((dynamic amount) {
      if (amount == null) {
        return '--';
      } else {
        final formattedAmount = double.tryParse(amount)?.toStringAsFixed(2);
        return (formattedAmount == null) ? '--' : '$formattedAmount USDt';
      }
    });

    final SideshiftAssetPair assetPair = SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(),
      to: asset == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
    );
    final currentPairInfo =
        ref.watch(sideshiftAssetPairInfoProvider(assetPair)).asData?.value;
    final min = formatAmount(currentPairInfo?.min);
    final max = formatAmount(currentPairInfo?.max);

    logger
        .d("[SideShift] sideShiftPendingOrder: ${currentPairInfo.toString()}");

    return Row(
      children: [
        Text(
          '${context.loc.min}: $min',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        Text(
          '${context.loc.max}: $max',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
