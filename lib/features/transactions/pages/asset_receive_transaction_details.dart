import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart' hide ResponsiveEx;
import 'package:ui_components/ui_components.dart';

class AssetReceiveTransactionDetails extends StatelessWidget {
  const AssetReceiveTransactionDetails(
    this.model, {
    super.key,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
    required this.onOpenUrl,
  });

  final ReceiveTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;
  final Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final isRefund = model.dbTransaction?.isBoltzRefund ?? false;
    final title = switch ((model.isPending, isRefund)) {
      (_, true) => context.loc.refund,
      (true, false) => context.loc.receiving,
      (false, false) => context.loc.received,
    };

    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        title: title,
        colors: context.aquaColors,
      ),
      extendBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: model.isLightning
            ? _LightningTransactionDetailsContent(
                model: model,
                onExplorerTap: onExplorerTap,
                onBlindingUrlTap: onBlindingUrlTap,
                onOpenUrl: onOpenUrl,
              )
            : _AquaTransactionDetailsContent(
                model: model,
                onExplorerTap: onExplorerTap,
                onBlindingUrlTap: onBlindingUrlTap,
              ),
      ),
    );
  }
}

class _AquaTransactionDetailsContent extends ConsumerWidget {
  const _AquaTransactionDetailsContent({
    required this.model,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
  });

  final ReceiveTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final receivedDisplayUnit =
        unitsProvider.getAssetDisplayUnit(model.receivedAsset);
    final dbTransaction = model.dbTransaction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Padding to account for the app bar
        const AppBarPadding(),
        AquaTransactionSummary.receive(
          assetId: model.receivedAsset.id,
          assetTicker: receivedDisplayUnit,
          assetIconUrl: model.receivedAsset.logoUrl,
          amountCrypto: model.receivedAmount,
          amountFiat: model.receivedAmountFiat,
          isPending: model.isPending,
          colors: context.aquaColors,
        ),
        SizedBox(height: model.isPending ? 4 : 18),
        AquaCard(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Column(
            children: [
              AquaListItem(
                title: context.loc.status,
                subtitleTrailing: model.confirmations,
                subtitleTrailingColor: context.aquaColors.accentSuccess,
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                title: context.loc.dateTime,
                subtitleTrailing: model.date,
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
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
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              if (dbTransaction != null &&
                  dbTransaction.exchangeRateAtExecution != null &&
                  dbTransaction.currencyAtExecution != null) ...[
                AquaListItem(
                  title: context.loc.assetTransactionDetailsValueAtTime,
                  titleTrailing:
                      '${dbTransaction.exchangeRateAtExecution} ${dbTransaction.currencyAtExecution}',
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              AquaListItem(
                onTap: () => onExplorerTap(
                  model.transactionId,
                  isBtc: model.receivedAsset.isBTC,
                ),
                title: model.receivedAsset.isLBTC
                    ? context.loc.viewInExplorer
                    : context.loc.viewInExplorer,
                titleColor: context.colorScheme.primary,
                iconTrailing: AquaIcon.externalLink(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              if (model.receivedAsset.isLiquid) ...[
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
    );
  }
}

class _LightningTransactionDetailsContent extends ConsumerWidget {
  const _LightningTransactionDetailsContent({
    required this.model,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
    required this.onOpenUrl,
  });

  final ReceiveTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;
  final Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final receivedDisplayUnit =
        unitsProvider.getAssetDisplayUnit(model.receivedAsset);
    final dbTransaction = model.dbTransaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Padding to account for the app bar
        const AppBarPadding(),
        AquaTransactionSummary.receive(
          assetId: Asset.lightning().id,
          assetTicker: receivedDisplayUnit,
          amountCrypto: model.receivedAmount,
          amountFiat: model.receivedAmountFiat,
          isPending: model.isPending,
          isLightning: model.isLightning,
          colors: context.aquaColors,
        ),
        SizedBox(height: model.isPending ? 4 : 18),
        AquaCard(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Column(
            children: [
              AquaListItem(
                title: context.loc.status,
                subtitleTrailing: model.confirmations,
                subtitleTrailingColor: context.aquaColors.accentSuccess,
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                title: context.loc.dateTime,
                subtitleTrailing: model.date,
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: () => context
                    .copyToClipboard(model.dbTransaction?.receiveAddress ?? ''),
                title: context.loc.destinationAddress,
                contentWidget: AquaColoredText(
                  text: model.dbTransaction?.receiveAddress ?? '',
                  style: AquaAddressTypography.body2.copyWith(
                    color: context.aquaColors.textPrimary,
                  ),
                ),
                iconTrailing: AquaIcon.copy(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: () =>
                    onOpenUrl(model.dbTransaction?.swapServiceUrl ?? ''),
                title: context.loc.provider,
                subtitleTrailing: model.dbTransaction?.swapServiceName,
                subtitleTrailingColor: context.aquaColors.accentBrand,
                iconTrailing: AquaIcon.externalLink(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: () => context
                    .copyToClipboard(model.dbTransaction?.serviceOrderId ?? ''),
                title: context.loc.boltzId,
                contentWidget: Text(
                  model.dbTransaction?.serviceOrderId ?? '',
                  style: AquaAddressTypography.body2.copyWith(
                    color: context.aquaColors.textPrimary,
                  ),
                ),
                iconTrailing: AquaIcon.copy(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: () => context
                    .copyToClipboard(model.dbTransaction?.serviceAddress ?? ''),
                title: context.loc.depositAddress,
                contentWidget: AquaColoredText(
                  text: model.dbTransaction?.serviceAddress ?? '',
                  style: AquaAddressTypography.body2.copyWith(
                    color: context.aquaColors.textPrimary,
                  ),
                  colorType: ColoredTextEnum.coloredIntegers,
                ),
                iconTrailing: AquaIcon.copy(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: () =>
                    onOpenUrl(model.dbTransaction?.swapServiceUrl ?? ''),
                title: context.loc.contactSwapServiceSupport(
                  model.dbTransaction?.swapServiceName?.split('.').first ?? '',
                ),
                iconTrailing: AquaIcon.chevronForward(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AquaCard(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Column(
            children: [
              AquaDivider(
                colors: context.aquaColors,
              ),
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
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              if (dbTransaction != null &&
                  dbTransaction.exchangeRateAtExecution != null &&
                  dbTransaction.currencyAtExecution != null) ...[
                AquaListItem(
                  title: context.loc.assetTransactionDetailsValueAtTime,
                  titleTrailing:
                      '${dbTransaction.exchangeRateAtExecution} ${dbTransaction.currencyAtExecution}',
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              AquaListItem(
                onTap: () => onExplorerTap(
                  model.transactionId,
                  isBtc: model.receivedAsset.isBTC,
                ),
                title: model.receivedAsset.isLBTC
                    ? context.loc.viewInExplorer
                    : context.loc.viewInExplorer,
                titleColor: context.colorScheme.primary,
                iconTrailing: AquaIcon.externalLink(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              if (model.receivedAsset.isLiquid) ...[
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
              if (model.feeAmount != null && model.feeAmountFiat != null) ...[
                const SizedBox(height: 16),
                AquaCard(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.transparent,
                  onTap: () {},
                  child: AquaListItem(
                    title: context.loc.totalFees,
                    titleTrailing: model.feeAmountFiat,
                    subtitleTrailing: model.feeAmount!.isNotEmpty
                        ? '${model.feeAmount} $receivedDisplayUnit'
                        : '',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
