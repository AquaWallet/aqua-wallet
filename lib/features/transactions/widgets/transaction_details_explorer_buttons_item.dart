import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

class TransactionDetailsExplorerButtons extends HookConsumerWidget {
  const TransactionDetailsExplorerButtons({
    super.key,
    required this.model,
  });

  final TransactionUiModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explorer =
        ref.watch(blockExplorerProvider.select((p) => p.currentBlockExplorer));

    return Column(
      children: [
        //ANCHOR - View transaction on explorer button
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onBackground,
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: model.mapOrNull(
            normal: (model) => () {
              final url =
                  model.asset.isBTC ? explorer.btcUrl : explorer.liquidUrl;
              final link = '$url${model.transaction.txhash}';
              ref.read(urlLauncherProvider).open(link);
            },
          ),
          child: model.asset.isLiquid
              ? Text(context.loc.assetTransactionDetailsLiquidExplorerButton)
              : Text(context.loc.assetTransactionDetailsExplorerButton),
        ),
        //ANCHOR - View unblinded transaction on explorer button
        if (model.asset.isLiquid) ...[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onBackground,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: model.mapOrNull(
              normal: (model) => () {
                final link = '${explorer.liquidUrl}${model.blindingUrl}';
                ref.read(urlLauncherProvider).open(link);
              },
            ),
            child: Text(
              context.loc.assetTransactionDetailsLiquidUnblindedExplorerButton,
            ),
          )
        ],
      ],
    );
  }
}
