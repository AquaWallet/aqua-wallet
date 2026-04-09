import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_summary_localizations_extension.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AssetPegTransactionDetails extends HookConsumerWidget {
  const AssetPegTransactionDetails(
    this.model, {
    super.key,
    required this.onExplorerTap,
    required this.onBlindingUrlTap,
  });

  final PegTransactionDetailsUiModel model;
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

    useEffect(() {
      ref.read(pegStatusProvider.notifier).requestPegStatus(
            orderId: model.orderId,
            isPegIn: model.deliverAsset.isBTC,
          );
      return null;
    }, []);

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
            const SizedBox(height: 24),
            AquaCard.glass(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    title: context.loc.dateTime,
                    subtitleTrailing: model.date,
                  ),
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    onTap: () => ref
                        .read(urlLauncherProvider)
                        .open(model.swapServiceUrl),
                    title: context.loc.provider,
                    subtitleTrailing: model.swapServiceName,
                    subtitleTrailingColor: context.aquaColors.accentBrand,
                    iconTrailing: AquaIcon.externalLink(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1.5),
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
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    onTap: () => context.copyToClipboard(model.orderId),
                    title: context.loc.serviceId(model.swapServiceName),
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
                  const SizedBox(height: 1.5),
                  AquaListItem(
                    onTap: () => ref
                        .read(urlLauncherProvider)
                        .open(model.swapServiceUrl),
                    title: context.loc.contactSwapServiceSupport(
                      model.swapServiceName.split('.').first,
                    ),
                    iconTrailing: AquaIcon.chevronForward(
                      size: 18,
                      color: context.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (model.transactionId.isNotEmpty) ...[
              AquaCard.glass(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 1.5),
                    TransactionNoteListItem(
                      txHash: model.transactionId,
                      note: model.notes,
                    ),
                    const SizedBox(height: 1.5),
                    AquaListItem(
                      onTap: () => onExplorerTap(
                        model.transactionId,
                        isBtc: model.explorerAsset?.isBTC ??
                            model.deliverAsset.isBTC,
                      ),
                      title: context.loc.viewInExplorer,
                      titleColor: context.colorScheme.primary,
                      iconTrailing: AquaIcon.externalLink(
                        size: 18,
                        color: context.aquaColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    if (model.explorerAsset?.isLiquid ??
                        model.deliverAsset.isLiquid) ...[
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
            ],
            if (!model.isPending && !model.isDirectPegInWithNoFee) ...[
              AquaCard.glass(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      ),
    );
  }
}
