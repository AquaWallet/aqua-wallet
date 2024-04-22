import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

class SideshiftMinMaxPanel extends HookConsumerWidget {
  const SideshiftMinMaxPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String formatAmount(dynamic amount) {
      if (amount == null) {
        return '--';
      } else {
        final formattedAmount = double.tryParse(amount)?.toStringAsFixed(2);
        return (formattedAmount == null) ? '--' : '$formattedAmount USDt';
      }
    }

    final asset = ref.read(sendAssetProvider);
    final SideshiftAssetPair assetPair = SideshiftAssetPair(
      from: SideshiftAsset.usdtLiquid(),
      to: asset == Asset.usdtEth()
          ? SideshiftAsset.usdtEth()
          : SideshiftAsset.usdtTron(),
    );
    final currentPairInfo =
        ref.watch(sideshiftPairInfoProvider(assetPair)).asData?.value;
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
