import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/providers/boltz_proof_of_payment_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class AssetSendTransactionDetails extends ConsumerWidget {
  const AssetSendTransactionDetails(
    this.model, {
    super.key,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
    required this.onRbfTap,
    required this.onOpenUrl,
  });

  final SendTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;
  final Function(String url) onOpenUrl;
  final Function(String txnId) onRbfTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTopUp = model.dbTransaction?.isTopUp ?? false;

    final title = model.isFeeTransaction
        ? context.loc.assetTxFeeLabel(model.feeForAsset!.ticker)
        : switch ((isTopUp, model.isPending)) {
            (true, true) => context.loc.assetTransactionsTypeToppingUp(
                model.dbTransaction?.serviceAddress ?? '',
              ),
            (true, false) => context.loc.assetTransactionsTypeTopup(
                model.dbTransaction?.serviceAddress ?? '',
              ),
            (false, true) => context.loc.sending,
            (false, false) => context.loc.sent,
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
        // The Lightning transaction details content is different from the
        //non-Lightning transaction details content
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
                onRbfTap: onRbfTap,
              ),
      ),
    );
  }
}

// Used for all Non-Lightning transactions
class _AquaTransactionDetailsContent extends ConsumerWidget {
  const _AquaTransactionDetailsContent({
    required this.model,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
    required this.onRbfTap,
  });

  final SendTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;
  final Function(String txnId) onRbfTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final displayUnit = unitsProvider.getAssetDisplayUnit(model.deliverAsset);

    final feeDisplayUnit = unitsProvider.getAssetDisplayUnit(model.feeAsset);
    final recipientGetsAmount = '${model.recepientGetsAmount}';
    final recipientGetsUnit =
        model.deliverAsset.getDisplayTicker(unitsProvider.currentDisplayUnit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Padding to account for the app bar
        const AppBarPadding(),
        if (model.deliverAmount != null && model.deliverAmount!.isNotEmpty) ...[
          AquaTransactionSummary.send(
            assetId: model.deliverAsset.id,
            assetTicker: displayUnit,
            assetIconUrl: model.deliverAsset.logoUrl,
            amountCrypto: model.deliverAmount!,
            amountFiat: model.deliverAmountFiat ?? '',
            isPending: model.isPending,
            colors: context.aquaColors,
          ),
          SizedBox(height: model.isPending ? 4 : 18),
        ],
        AquaCard(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Column(
            children: [
              AquaListItem(
                title: context.loc.status,
                subtitleTrailing:
                    model.isFailed ? context.loc.failed : model.confirmations,
                subtitleTrailingColor: model.isFailed
                    ? context.aquaColors.accentDanger
                    : context.aquaColors.accentSuccess,
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                title: context.loc.dateTime,
                subtitleTrailing: model.date,
              ),
              if (model.dbTransaction != null &&
                  model.dbTransaction!.swapServiceName != null &&
                  model.dbTransaction!.serviceOrderId != null) ...[
                AquaDivider(
                  colors: context.aquaColors,
                ),
                AquaListItem(
                  title: context.loc.provider,
                  titleTrailing: model.dbTransaction!.swapServiceName,
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
                AquaListItem(
                  title: context.loc
                      .serviceId(model.dbTransaction!.swapServiceName ?? ''),
                  contentWidget: Text(
                    model.dbTransaction?.serviceOrderId ?? '',
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textPrimary,
                    ),
                  ),
                  onTap: () => context.copyToClipboard(
                      model.dbTransaction!.serviceOrderId ?? ''),
                  iconTrailing: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                ),
              ],
              AquaDivider(
                colors: context.aquaColors,
              ),
              AquaListItem(
                onTap: model.receiveAddress != null
                    ? () => context.copyToClipboard(model.receiveAddress!)
                    : null,
                title: context.loc.destinationAddress,
                contentWidget: AquaColoredText(
                  text: model.receiveAddress ?? '',
                  style: AquaAddressTypography.body2.copyWith(
                    color: context.aquaColors.textPrimary,
                  ),
                  colorType: ColoredTextEnum.coloredIntegers,
                  shouldWrap: true,
                ),
                iconTrailing: AquaIcon.copy(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              AquaDivider(
                colors: context.aquaColors,
              ),
              if (model.recepientGetsAmount != null &&
                  !model.isFailed &&
                  !model.isFeeTransaction) ...[
                AquaListItem(
                    onTap: () => context.copyToClipboard(recipientGetsAmount),
                    title: context.loc.recipientGets,
                    subtitleTrailing: '$recipientGetsAmount $recipientGetsUnit',
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    )),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
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
              if (model.fiatAmountAtExecutionDisplay != null) ...[
                AquaListItem(
                  title: context.loc.assetTransactionDetailsValueAtTime,
                  subtitleTrailing: model.fiatAmountAtExecutionDisplay!,
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              AquaListItem(
                onTap: () => onExplorerTap(
                  model.transactionId,
                  isBtc: model.deliverAsset.isBTC,
                ),
                title: model.deliverAsset.isLBTC
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
              if (model.blindingUrl != null &&
                  model.blindingUrl!.isNotEmpty) ...[
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
        if (!model.isFeeTransaction && model.feeAmount != null) ...[
          const SizedBox(height: 16),
          AquaCard(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            onTap: () {},
            child: AquaListItem(
              title: context.loc.totalFees,
              titleTrailing: model.feeAmountFiat,
              subtitleTrailing: model.feeAmount?.isNotEmpty ?? false
                  ? '${model.feeAmount} $feeDisplayUnit'
                  : '',
            ),
          ),
        ],
        if (model.isFeeTransaction) ...[
          const SizedBox(height: 16),
          AquaToast(
            title: context.loc.assetTxFeeLabel(model.feeForAsset!.ticker),
            description:
                context.loc.assetFeeTxTooltipText(model.feeForAsset!.ticker),
            variant: AquaToastVariant.normal,
            aquaColors: context.aquaColors,
            actions: [
              AquaToastAction(
                title: context.loc.usdtFeeTxTooltipTextLearnMore,
                onPressed: () => ref
                    .read(urlLauncherProvider)
                    .open(usdtFeeTransactionInfoUrl),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (model.canRbf) ...[
          const SizedBox(height: 16),
          AquaButton.primary(
            text: context.loc.increaseFee,
            onPressed: () {
              // Use transactionId directly since dbTransaction might be null
              final txId = model.dbTransaction?.txhash ?? model.transactionId;
              onRbfTap(txId);
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// Used only for Lightning transactions
class _LightningTransactionDetailsContent extends ConsumerWidget {
  const _LightningTransactionDetailsContent({
    required this.model,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
    required this.onOpenUrl,
  });

  final SendTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;
  final Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final displayUnit = unitsProvider.getAssetDisplayUnit(model.deliverAsset);

    final feeDisplayUnit = unitsProvider.getAssetDisplayUnit(model.feeAsset);
    final boltzOrderId =
        model.isLightning ? model.dbTransaction?.serviceOrderId : null;
    final proofOfPaymentUrl =
        ref.watch(boltzProofOfPaymentProvider(boltzOrderId)).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Padding to account for the app bar
        const AppBarPadding(),
        if (model.deliverAmount != null && model.deliverAmount!.isNotEmpty) ...[
          AquaTransactionSummary.send(
            assetId: Asset.lightning().id,
            assetTicker: displayUnit,
            amountCrypto: model.deliverAmount!,
            amountFiat: model.deliverAmountFiat ?? '',
            isPending: model.isPending,
            isLightning: model.isLightning,
            colors: context.aquaColors,
          ),
          SizedBox(height: model.isPending ? 4 : 18),
        ],
        AquaCard(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
          child: Column(
            children: [
              AquaListItem(
                title: context.loc.status,
                subtitleTrailing:
                    model.isFailed ? context.loc.failed : model.confirmations,
                subtitleTrailingColor: model.isFailed
                    ? context.aquaColors.accentDanger
                    : context.aquaColors.accentSuccess,
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
              if (model.receiveAddress != null &&
                  model.receiveAddress!.isNotEmpty) ...[
                AquaListItem(
                  onTap: () => context.copyToClipboard(model.receiveAddress!),
                  title: model.isLightning
                      ? context.loc.recipient
                      : context.loc.destinationAddress,
                  contentWidget: AquaColoredText(
                    text: model.receiveAddress!,
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textPrimary,
                    ),
                    shouldWrap: true,
                  ),
                  iconTrailing: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              if (model.recepientGetsAmount != null && !model.isFailed) ...[
                AquaListItem(
                  title: context.loc.recipientGets,
                  subtitleTrailing: '${model.recepientGetsAmount} $displayUnit',
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              AquaListItem(
                onTap: model.dbTransaction?.swapServiceUrl != null
                    ? () => onOpenUrl(model.dbTransaction!.swapServiceUrl!)
                    : null,
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
                onTap: model.dbTransaction?.serviceOrderId != null
                    ? () => context
                        .copyToClipboard(model.dbTransaction!.serviceOrderId!)
                    : null,
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
                onTap: model.dbTransaction?.serviceAddress != null
                    ? () => context
                        .copyToClipboard(model.dbTransaction!.serviceAddress!)
                    : null,
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
                onTap: model.dbTransaction?.swapServiceUrl != null
                    ? () => onOpenUrl(model.dbTransaction!.swapServiceUrl!)
                    : null,
                title: context.loc.contactSwapServiceSupport(
                  model.dbTransaction?.swapServiceName?.split('.').first ?? '',
                ),
                iconTrailing: AquaIcon.chevronForward(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              if (proofOfPaymentUrl != null) ...[
                AquaDivider(
                  colors: context.aquaColors,
                ),
                AquaListItem(
                  onTap: () => onOpenUrl(proofOfPaymentUrl),
                  title: context.loc.proofOfPayment,
                  iconTrailing: AquaIcon.externalLink(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                ),
              ],
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
              if (model.fiatAmountAtExecutionDisplay != null) ...[
                AquaListItem(
                  title: context.loc.assetTransactionDetailsValueAtTime,
                  subtitleTrailing: model.fiatAmountAtExecutionDisplay!,
                ),
                AquaDivider(
                  colors: context.aquaColors,
                ),
              ],
              AquaListItem(
                onTap: () => onExplorerTap(
                  model.transactionId,
                  isBtc: model.deliverAsset.isBTC,
                ),
                title: model.deliverAsset.isLBTC
                    ? context.loc.viewInExplorer
                    : context.loc.viewInExplorer,
                titleColor: context.colorScheme.primary,
                iconTrailing: AquaIcon.externalLink(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
              ),
              if (model.deliverAsset.isLiquid &&
                  model.blindingUrl != null &&
                  model.blindingUrl!.isNotEmpty) ...[
                AquaDivider(
                  colors: context.aquaColors,
                ),
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
        if (model.feeAmount != null && model.feeAmount!.isNotEmpty) ...[
          const SizedBox(height: 16),
          AquaCard(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            onTap: () {},
            child: AquaListItem(
              title: context.loc.totalFees,
              titleTrailing: model.feeAmountFiat,
              subtitleTrailing: '${model.feeAmount} $feeDisplayUnit',
            ),
          ),
        ],
        if (model.isFeeTransaction) ...[
          const SizedBox(height: 16),
          AquaToast(
            title: context.loc.assetTxFeeLabel(model.feeForAsset!.ticker),
            description:
                context.loc.assetFeeTxTooltipText(model.feeForAsset!.ticker),
            variant: AquaToastVariant.normal,
            aquaColors: context.aquaColors,
            actions: [
              AquaToastAction(
                title: context.loc.usdtFeeTxTooltipTextLearnMore,
                onPressed: () => ref
                    .read(urlLauncherProvider)
                    .open(usdtFeeTransactionInfoUrl),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
