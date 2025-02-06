import 'package:aqua/common/common.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';

class TransactionInfoCard extends StatelessWidget {
  const TransactionInfoCard({
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
          if (arguments.amountFiat != null && !asset.isNonSatsAsset) ...{
            //ANCHOR - Amount
            TransactionInfoItem(
              label: context.loc.amount,
              value: '${arguments.amountFiat}',
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
            ),
            const SizedBox(height: 18),
          },
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenFeeLabel,
            value: arguments.feeSats != null ? feeAmount : '-',
            padding: const EdgeInsets.symmetric(horizontal: 26.0),
          ),
          const SizedBox(height: 22.0),
          //ANCHOR - Notes
          // ExpandableContainer(
          //   padding: EdgeInsets.only(left: 26.0, right: 6.0),
          //   title: Text(
          //     context.loc.sendAssetCompleteScreenNoteLabel,
          //     style: Theme.of(context).textTheme.labelLarge?.copyWith(
          //           color: Theme.of(context).colorScheme.onSurface,
          //           fontWeight: FontWeight.w400,
          //         ),
          //   ),
          //   child: Container(
          //     padding: EdgeInsets.only(bottom: 18.0),
          //     child: Text(
          //       arguments.note ?? '',
          //       textAlign: TextAlign.start,
          //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
          //             color: Theme.of(context).colors.onBackground,
          //             fontWeight: FontWeight.w400,
          //           ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
