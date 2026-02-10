import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BitcoinShowRecipientSideSheet extends HookWidget {
  const BitcoinShowRecipientSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Recipient',
      showBackButton: false,
      children: [
        ListView.separated(
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return OutlineContainer(
              aquaColors: aquaColors,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AquaListItem(
                    colors: aquaColors,
                    title: 'Chip $index',
                    titleColor: aquaColors.textPrimary,
                    iconLeading: AquaIcon.pokerchip(
                      color: aquaColors.accentBrand,
                    ),
                    titleTrailing: '0.0001 BTC',
                    titleTrailingColor: aquaColors.textSecondary,
                    iconTrailing: AquaIcon.edit(
                      color: aquaColors.textSecondary,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  AquaAddressItem(
                    address:
                        'VJLA47dgoUnGSiAGrbaKsQkEdLnJcQQFmtW4ebG9A1tcycshvKY8d9NoKREkDiT5QhURJjmAUhE2MpVq',
                    colors: aquaColors,
                    copyable: true,
                    onTap: (p0) => context.copyToClipboard(p0 ?? ''),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemCount: 4,
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: BitcoinShowRecipientSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ChipSweepTransactionSummarySideSheet extends HookWidget {
  const ChipSweepTransactionSummarySideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Chip Sweep',
      showBackButton: false,
      children: [
        AquaTransactionSummary.receive(
          assetId: AssetIds.btc,
          isPending: false,
          assetTicker: AssetIds.btc,
          amountCrypto: '0.49584475',
          amountFiat: '\$4,558.51',
          colors: aquaColors,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                title: loc.status,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: '1 Confirmation',
                subtitleTrailingColor: aquaColors.accentSuccess,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.dateTime,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: 'Jan 17, 2025 3:45 PM',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
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
              const Divider(height: 0),
              AquaListItem(
                title: loc.assetTransactionDetailsValueAtTime,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: '\$4,558.51',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.assetTransactionDetailsExplorerButton,
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
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: ChipSweepTransactionSummarySideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class ChipLoadTransactionSummarySideSheet extends HookWidget {
  const ChipLoadTransactionSummarySideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Chip Load',
      showBackButton: false,
      children: [
        AquaTransactionSummary.send(
          assetId: AssetIds.btc,
          isPending: false,
          assetTicker: AssetIds.btc,
          amountCrypto: '-0.49584475',
          amountFiat: '-\$4,558.51',
          colors: aquaColors,
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                iconLeading: AquaIcon.pokerchip(
                  color: aquaColors.textPrimary,
                ),
                title: 'Chip Load',
                titleColor: aquaColors.textPrimary,
                titleTrailing: '20 Chips',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: 'x0.001 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.chevronRight(
                  color: aquaColors.textSecondary,
                ),
              ),
              const Divider(height: 0),
              AquaListItem(
                iconLeading: AquaIcon.pokerchip(
                  color: aquaColors.textPrimary,
                ),
                title: 'Chip Load',
                titleColor: aquaColors.textPrimary,
                titleTrailing: '5 Chips',
                titleTrailingColor: aquaColors.textPrimary,
                subtitleTrailing: 'x0.02 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.chevronRight(
                  color: aquaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlineContainer(
          aquaColors: aquaColors,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaListItem(
                title: loc.status,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: '1 Confirmation',
                subtitleTrailingColor: aquaColors.accentSuccess,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.dateTime,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: 'Jan 17, 2025 3:45 PM',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.recipientGets,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: '0.49584475 BTC',
                subtitleTrailingColor: aquaColors.textSecondary,
                iconTrailing: AquaIcon.copy(
                  color: aquaColors.textSecondary,
                ),
                onTap: () => context.copyToClipboard('0.49584475 BTC'),
              ),
              const Divider(height: 0),
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
              const Divider(height: 0),
              AquaListItem(
                title: loc.assetTransactionDetailsValueAtTime,
                backgroundColor: aquaColors.surfacePrimary,
                subtitleTrailing: '\$4,558.51',
                subtitleTrailingColor: aquaColors.textSecondary,
              ),
              const Divider(height: 0),
              AquaListItem(
                title: loc.assetTransactionDetailsExplorerButton,
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
        const SizedBox(height: 24),
        OutlineContainer(
          aquaColors: aquaColors,
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
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: ChipLoadTransactionSummarySideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
