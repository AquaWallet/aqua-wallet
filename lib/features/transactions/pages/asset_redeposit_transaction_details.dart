import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class AssetRedepositTransactionDetails extends HookConsumerWidget {
  const AssetRedepositTransactionDetails(
    this.model, {
    super.key,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
  });

  final RedepositTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final displayUnit = unitsProvider.getAssetDisplayUnit(model.asset);
    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        title: model.isPending
            ? context.loc.redepositing
            : context.loc.redeposited,
        colors: context.aquaColors,
      ),
      extendBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Padding to account for the app bar
            const AppBarPadding(),
            AquaTransactionSummary.receive(
              assetId: model.asset.id,
              assetTicker: displayUnit,
              assetIconUrl: model.asset.logoUrl,
              amountCrypto: model.amount,
              amountFiat: model.amountFiat,
              isPending: model.isPending,
              isConfidential: model.isConfidential,
              colors: context.aquaColors,
            ),
            SizedBox(height: model.isPending ? 4 : 18),
            AquaCard.glass(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  AquaListItem(
                    title: context.loc.status,
                    subtitleTrailing: model.confirmations,
                    subtitleTrailingColor: context.aquaColors.accentSuccess,
                  ),
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    title: context.loc.dateTime,
                    subtitleTrailing: model.date,
                  ),
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    onTap: () => context.copyToClipboard(model.transactionId),
                    title: context.loc.transactionID,
                    contentWidget: Text(
                      model.transactionId,
                      style: AquaAddressTypography.body2.copyWith(
                        color: context.aquaColors.textPrimary,
                      ),
                    ),
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  TransactionNoteListItem(
                    txHash: model.transactionId,
                    note: model.notes,
                  ),
                  const SizedBox(height: 1.5),
                  //TODO - Implement feature to receive value at time
                  // AquaListItem(
                  //   title: context.loc.valueAtTime,
                  // ),
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    onTap: () => onExplorerTap(
                      model.transactionId,
                      isBtc: model.asset.isBTC,
                    ),
                    title: model.asset.isLBTC
                        ? context.loc.viewInExplorer
                        : context.loc.viewInExplorer,
                    titleColor: context.colorScheme.primary,
                    iconTrailing: AquaIcon.externalLink(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  if (model.asset.isLiquid) ...[
                    AquaListItem(
                      onTap: model.blindingUrl != null
                          ? () => onBlindingUrlTap(model.blindingUrl!)
                          : null,
                      title: context.loc.viewUnblindedTxInExplorer,
                      titleColor: context.colorScheme.primary,
                      iconTrailing: AquaIcon.externalLink(
                        size: 18,
                        color: context.aquaColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
