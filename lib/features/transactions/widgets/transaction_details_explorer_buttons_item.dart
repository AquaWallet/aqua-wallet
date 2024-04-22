import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TransactionDetailsExplorerButtons extends HookConsumerWidget {
  const TransactionDetailsExplorerButtons({
    super.key,
    required this.model,
  });

  final TransactionUiModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tuple = useMemoized(() => (model.asset, model.transaction));
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
          onPressed: () {
            final url = tuple.$1.isBTC ? explorer.btcUrl : explorer.liquidUrl;
            final link = '$url${tuple.$2.txhash}';
            ref.read(urlLauncherProvider).open(link);
          },
          child: tuple.$1.isLiquid
              ? Text(context.loc.assetTransactionDetailsLiquidExplorerButton)
              : Text(context.loc.assetTransactionDetailsExplorerButton),
        ),
        //ANCHOR - View unblinded transaction on explorer button
        if (tuple.$1.isLiquid) ...[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onBackground,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final out = tuple.$2.outputs?.firstWhere(
                  (e) => (e.amountBlinder != null && e.assetBlinder != null));
              final link =
                  '${explorer.liquidUrl}${tuple.$2.txhash}#blinded=${out?.satoshi},${out?.assetId},${out?.amountBlinder},${out?.assetBlinder}';
              ref.read(urlLauncherProvider).open(link);
            },
            child: Text(
              context.loc.assetTransactionDetailsLiquidUnblindedExplorerButton,
            ),
          )
        ],
      ],
    );
  }
}
