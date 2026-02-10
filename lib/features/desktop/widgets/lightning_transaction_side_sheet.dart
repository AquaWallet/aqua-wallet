import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/transaction_summary_localizations_extension.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LightningTransactionSideSheet extends HookWidget {
  LightningTransactionSideSheet.send({
    required this.iconAssetId,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    required this.colors,
    this.isPending = false,
    this.isFailed = false,
    super.key,
  })  : _type = AquaTransactionType.send,
        _transactionSummaryWidget = AquaTransactionSummary.send(
          assetId: iconAssetId,
          isPending: isPending,
          assetTicker: _getAssetTicker(iconAssetId),
          amountCrypto: amountCrypto,
          amountFiat: amountCrypto,
          colors: colors,
        );

  LightningTransactionSideSheet.receive({
    required this.iconAssetId,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    required this.colors,
    this.isPending = false,
    this.isFailed = false,
    super.key,
  })  : _type = AquaTransactionType.receive,
        _transactionSummaryWidget = AquaTransactionSummary.receive(
          assetId: iconAssetId,
          isPending: isPending,
          assetTicker: _getAssetTicker(iconAssetId),
          amountCrypto: amountCrypto,
          amountFiat: amountCrypto,
          colors: colors,
        );

  LightningTransactionSideSheet.swap({
    required String fromAssetTicker,
    required String toAssetTicker,
    required this.timestamp,
    required this.amountCrypto,
    required this.amountFiat,
    this.isPending = false,
    this.isFailed = false,
    this.iconAssetId = '',
    required this.colors,
    required AppLocalizations loc,
    super.key,
  })  : _type = AquaTransactionType.swap,
        _transactionSummaryWidget = AquaSwapTransactionSummary(
          fromAssetId: fromAssetTicker,
          toAssetId: toAssetTicker,
          fromAssetTicker: _getAssetTicker(fromAssetTicker),
          toAssetTicker: _getAssetTicker(toAssetTicker),
          fromAmountCrypto: amountCrypto,
          toAmountCrypto: amountFiat,
          isPending: isPending,
          colors: colors,
          text: loc.transactionSummaryLocalizations,
        );

  final String iconAssetId;
  final DateTime timestamp;
  final String amountCrypto;
  final String amountFiat;
  final bool isPending;
  final bool isFailed;
  final AquaColors colors;
  final Widget _transactionSummaryWidget;
  final AquaTransactionType _type;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final aquaColors = context.aquaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                AquaText.subtitleSemiBold(text: getTitle(loc)),
                AquaIcon.close(
                  color: aquaColors.textPrimary,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24, top: 16),
            child: StylizedDivider(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                shrinkWrap: true,
                children: [
                  _transactionSummaryWidget,
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: aquaColors.surfacePrimary,
                    ),
                    child: Column(
                      children: [
                        AquaListItem(
                          title: loc.status,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: getStatusText(loc, '1'),
                          subtitleTrailingColor: getStatusColor(aquaColors),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.dateTime,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: 'Jan 17, 2025 3:45 PM',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.destinationAddress,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          contentWidget: AquaColoredText(
                            text:
                                'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297',
                            style: AquaAddressTypography.body2.copyWith(
                              color: aquaColors.textSecondary,
                            ),
                            colorType: ColoredTextEnum.coloredIntegers,
                          ),
                          onTap: () => context.copyToClipboard(
                              'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297'),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.recipientGets,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: '0.49584475 BTC',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.provider,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: 'Boltz',
                          subtitleTrailingColor: aquaColors.accentBrand,
                          iconTrailing: AquaIcon.externalLink(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () => debugPrint('Open external link or page'),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.boltzId,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitle: 'bArmJxFZh9PK',
                          subtitleColor: aquaColors.textSecondary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'bArmJxFZh9PK',
                          ),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.depositAddress,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          contentWidget: AquaColoredText(
                            text:
                                'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297',
                            style: AquaAddressTypography.body2.copyWith(
                              color: aquaColors.textSecondary,
                            ),
                            colorType: ColoredTextEnum.coloredIntegers,
                          ),
                          onTap: () => context.copyToClipboard(
                              'bc1p5d7rjq7g6rdk2yhzks9smlaqtedr4dekq08ge8ztwac72sfr9rusxg3297'),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.contactSideswapSupport,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.chevronRight(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () => debugPrint('Open date time details'),
                        ),
                        const StylizedDivider(),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: aquaColors.surfacePrimary,
                    ),
                    child: Column(
                      children: [
                        AquaListItem(
                          title: loc.transactionID,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitle: 'TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H',
                          subtitleColor: aquaColors.textSecondary,
                          iconTrailing: AquaIcon.copy(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () async => context.copyToClipboard(
                            'TYseuBSHmwzgHthcr18y5a5N8jsYsa4t3H',
                          ),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.assetTransactionDetailsValueAtTime,
                          backgroundColor: aquaColors.surfacePrimary,
                          subtitleTrailing: '\$4,558.51',
                          subtitleTrailingColor: aquaColors.textSecondary,
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.viewInExplorer,
                          titleColor: aquaColors.accentBrand,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.externalLink(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () => debugPrint('Open external link or page'),
                        ),
                        const StylizedDivider(),
                        AquaListItem(
                          title: loc.viewUnblindedTxInExplorer,
                          titleColor: aquaColors.accentBrand,
                          backgroundColor: aquaColors.surfacePrimary,
                          iconTrailing: AquaIcon.externalLink(
                            color: aquaColors.textSecondary,
                          ),
                          onTap: () => debugPrint('Open external link or page'),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: aquaColors.surfacePrimary,
                    ),
                    child: AquaListItem(
                      title: loc.totalFees,
                      backgroundColor: aquaColors.surfacePrimary,
                      titleTrailing: '\$3.48',
                      subtitleTrailing: '0.0000612 BTC',
                      subtitleTrailingColor: aquaColors.textSecondary,
                      iconTrailing: AquaIcon.chevronDown(
                        color: aquaColors.textSecondary,
                      ),
                      onTap: () {
                        debugPrint('Expands something?');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(AquaColors aquaColors) {
    if (isPending) {
      return aquaColors.accentBrand;
    } else if (isFailed) {
      return aquaColors.accentDanger;
    } else {
      return aquaColors.accentSuccess;
    }
  }

  String getStatusText(AppLocalizations tl, [String? confirmations]) {
    if (isPending) {
      return tl.pending;
    } else if (isFailed) {
      return tl.failed;
    } else {
      return '${confirmations ?? ''} Confirmations';
    }
  }

  static String _getAssetTicker(String assetId) => switch (assetId) {
        AssetIds.btc => 'BTC',
        _ when (AssetIds.lbtc.contains(assetId)) => 'L-BTC',
        _ when (AssetIds.isAnyUsdt(assetId)) => 'USDt',
        AssetIds.lightning => 'Lightning',
        _ => throw UnimplementedError(),
      };

  String getTitle(AppLocalizations loc) => switch (_type) {
        AquaTransactionType.receive =>
          !isFailed && !isPending ? loc.received : loc.receiving,
        AquaTransactionType.send =>
          !isFailed && !isPending ? loc.sent : loc.sending,
        AquaTransactionType.swap =>
          !isFailed && !isPending ? loc.swapped : loc.swapping,
      };
}
