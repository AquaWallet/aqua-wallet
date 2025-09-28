import 'package:aqua/common/common.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

class TopUpTransactionInfoCard extends StatelessWidget {
  const TopUpTransactionInfoCard({
    super.key,
    required this.arguments,
  });

  final SendAssetCompletionArguments arguments;

  @override
  Widget build(BuildContext context) {
    final asset = arguments.asset;
    final amount = (Decimal.fromInt(arguments.feeSats ?? 0) /
            DecimalExt.fromAssetPrecision(asset.precision))
        .toDouble();
    final feeAmount = arguments.feeAsset == FeeAsset.tetherUsdt
        ? '\$${amount.toStringAsFixed(2)}'
        : '${arguments.feeSats ?? '0'} ${SupportedDisplayUnits.sats.value}';

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 22.0),
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenFeeLabel,
            value: arguments.feeSats != null ? feeAmount : '-',
            padding: const EdgeInsets.symmetric(horizontal: 26.0),
          ),
          const SizedBox(height: 22.0),
        ],
      ),
    );
  }
}
