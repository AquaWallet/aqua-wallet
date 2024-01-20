import 'package:aqua/features/external/boltz/boltz_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
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
    final boltzSwapData = ref
        .watch(boltzSwapFromTxHashProvider(model.transaction.txhash ?? ''))
        .asData
        ?.value;
    final explorer =
        ref.watch(blockExplorerProvider.select((p) => p.currentBlockExplorer));

    return Padding(
      padding: EdgeInsets.only(
        left: 8.w,
        right: 8.w,
        bottom: 24.h,
      ),
      child: Center(
        child: Column(
          children: [
            //ANCHOR - View transaction on explorer button
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                final url =
                    tuple.$1.isBTC ? explorer.btcUrl : explorer.liquidUrl;
                final link = '$url${tuple.$2.txhash}';
                ref.read(urlLauncherProvider).open(link);
              },
              child: tuple.$1.isLiquid
                  ? Text(AppLocalizations.of(context)!
                      .assetTransactionDetailsLiquidExplorerButton)
                  : Text(AppLocalizations.of(context)!
                      .assetTransactionDetailsExplorerButton),
            ),
            //ANCHOR - View unblinded transaction on explorer button
            if (tuple.$1.isLiquid) ...[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: () {
                  final out = tuple.$2.outputs?.firstWhere((e) =>
                      (e.amountBlinder != null && e.assetBlinder != null));
                  final link =
                      '${explorer.liquidUrl}${tuple.$2.txhash}#blinded=${out?.satoshi},${out?.assetId},${out?.amountBlinder},${out?.assetBlinder}';
                  ref.read(urlLauncherProvider).open(link);
                },
                child: Text(AppLocalizations.of(context)!
                    .assetTransactionDetailsLiquidUnblindedExplorerButton),
              )
            ],
            //ANCHOR - Boltz Status/Refund Button
            SizedBox(height: 20.h),
            if (boltzSwapData != null) ...[
              BoltzSwapStatusButton(swapData: boltzSwapData),
            ],
          ],
        ),
      ),
    );
  }
}
