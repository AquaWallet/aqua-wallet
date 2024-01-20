import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

class AssetAmountRangePanel extends HookConsumerWidget {
  const AssetAmountRangePanel({super.key});

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

    final currentPairInfo = ref.watch(sideshiftCurrentPairInfoProvider);
    final min = formatAmount(currentPairInfo?.min);
    final max = formatAmount(currentPairInfo?.max);

    logger
        .d("[SideShift] sideShiftPendingOrder: ${currentPairInfo.toString()}");

    return Row(
      children: <Widget>[
        Text(
          '${AppLocalizations.of(context)!.min}: $min',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        Text(
          '${AppLocalizations.of(context)!.max}: $max',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
