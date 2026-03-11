import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_summary_localizations_extension.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class AssetSwapTransactionDetails extends HookConsumerWidget {
  const AssetSwapTransactionDetails(
    this.model, {
    super.key,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
  });

  final SwapTransactionDetailsUiModel model;
  final OnExplorerTap onExplorerTap;
  final OnBlindingUrlTap onBlindingUrlTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsProvider = ref.watch(displayUnitsProvider);
    final deliverDisplayUnit =
        unitsProvider.getAssetDisplayUnit(model.deliverAsset);
    final receiveDisplayUnit =
        unitsProvider.getAssetDisplayUnit(model.receiveAsset);
    final formatter = ref.watch(formatProvider);
    final feeDisplayUnit = unitsProvider.getAssetDisplayUnit(model.feeAsset);

    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        title: model.isPending ? context.loc.swapping : context.loc.swapped,
        colors: context.aquaColors,
      ),
      extendBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Padding to account for the app bar
            const AppBarPadding(),
            AquaSwapTransactionSummary(
              fromAssetId: model.deliverAsset.id,
              fromAssetTicker: deliverDisplayUnit,
              fromAssetIconUrl: model.deliverAsset.logoUrl,
              fromAmountCrypto: model.deliverAmount,
              toAssetId: model.receiveAsset.id,
              toAssetTicker: receiveDisplayUnit,
              toAssetIconUrl: model.receiveAsset.logoUrl,
              toAmountCrypto: model.receiveAmount,
              isPending: model.isPending,
              colors: context.aquaColors,
              text: context.loc.transactionSummaryLocalizations,
            ),
            SizedBox(height: model.isPending ? 4 : 22),
            AquaCard(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
              child: Column(
                children: [
                  AquaListItem(
                    title: context.loc.status,
                    subtitleTrailing: model.isPending
                        ? context.loc.pending
                        : formatter.formatConfirmations(
                            context.loc, model.confirmationCount),
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
                    onTap: () => context.copyToClipboard(model.depositAddress),
                    title: context.loc.depositAddress,
                    contentWidget: AquaColoredText(
                      text: model.depositAddress,
                      style: AquaAddressTypography.body2.copyWith(
                        color: context.aquaColors.textPrimary,
                      ),
                      colorType: ColoredTextEnum.coloredIntegers,
                    ),
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AquaDivider(
                    colors: context.aquaColors,
                  ),
                  AquaListItem(
                    onTap: () => context.copyToClipboard(model.orderId),
                    title: model.swapServiceName.isNotEmpty
                        ? context.loc.serviceId(model.swapServiceName)
                        : context.loc.orderId,
                    contentWidget: Text(
                      model.orderId,
                      style: AquaAddressTypography.body2.copyWith(
                        color: context.aquaColors.textPrimary,
                      ),
                    ),
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (model.swapServiceUrl.isNotEmpty) ...[
                    AquaDivider(
                      colors: context.aquaColors,
                    ),
                    AquaListItem(
                      onTap: () => ref
                          .read(urlLauncherProvider)
                          .open(model.swapServiceUrl),
                      title: context.loc.contactSwapServiceSupport(
                        model.swapServiceName.split('.').first,
                      ),
                      iconTrailing: AquaIcon.chevronRight(
                        size: 18,
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (model.swapServiceName.isNotEmpty) ...[
                      AquaDivider(
                        colors: context.aquaColors,
                      ),
                      AquaListItem(
                        title: context.loc.provider,
                        subtitleTrailing: model.swapServiceName,
                        subtitleTrailingColor: context.aquaColors.accentBrand,
                        iconTrailing: AquaIcon.externalLink(
                          size: 18,
                          color: context.aquaColors.textSecondary,
                        ),
                      ),
                    ],
                  ]
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
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  AquaDivider(
                    colors: context.aquaColors,
                  ),
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
                  if (model.deliverAsset.isLiquid) ...[
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
            const SizedBox(height: 16),
            AquaCard(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
              onTap: () {},
              child: AquaListItem(
                title: context.loc.totalFees,
                titleTrailing: model.feeAmountFiat,
                subtitleTrailing: model.feeAmount.isNotEmpty
                    ? '${model.feeAmount} $feeDisplayUnit'
                    : '',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
