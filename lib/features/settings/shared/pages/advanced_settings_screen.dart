import 'package:aqua/features/pokerchip/pages/pages.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/mixins/mixins.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class AdvancedSettingsScreen extends HookConsumerWidget
    with ExportTransactionMixin {
  const AdvancedSettingsScreen({super.key});

  static const routeName = '/settings/advanced';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirectPegInEnabled =
        ref.watch(prefsProvider.select((p) => p.isDirectPegInEnabled));
    final experimentalFeaturesEnabled = ref.watch(featureUnlockTapCountProvider
        .select((p) => p.experimentalFeaturesEnabled));

    // ref.listen(
    //   walletRemoveRequestProvider,
    //   (_, state) => state.maybeWhen(
    //     success: () async {
    //       await ref.read(backupReminderProvider).clear();
    //       Restart.restartApp();
    //       return null;
    //     },
    //     failure: () => context.showErrorSnackbar(
    //       context.loc.removeWalletScreenRemoveFailed,
    //     ),
    //     verificationFailed: () => context.showErrorSnackbar(
    //       context.loc.verificationFailed,
    //     ),
    //     orElse: () => null,
    //   ),
    // );

    listenToExportTransactionHistoryEvents(context, ref);
    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        title: context.loc.settingsScreenSectionAdvanced,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              //ANCHOR - Direct Peg In
              AquaListItem(
                key: SettingsScreenKeys.settingsDirectPegInButton,
                title: context.loc.directPegIn,
                iconLeading: AquaIcon.pegIn(
                  size: 24,
                  color: context.aquaColors.textSecondary,
                ),
                iconTrailing: AquaToggle(
                  value: isDirectPegInEnabled,
                  trackColor: context.aquaColors.surfaceSecondary,
                ),
                onTap: () => ref.read(prefsProvider).switchDirectPegIn(),
              ),
              const SizedBox(height: 1.0),
              //ANCHOR - Poker Chip
              AquaListItem(
                iconLeading: AquaIcon.pokerchip(
                  size: 24,
                  color: context.aquaColors.textSecondary,
                ),
                iconTrailing: AquaIcon.chevronForward(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
                title: context.loc.bitcoinChip,
                onTap: () => context.push(PokerchipScannerScreen.routeName),
              ),
              const SizedBox(height: 1.0),
              //Anchor - BTCPay Server
              // TODO: Uncomment when BTCPay Server is implemented
              // AquaListItem(
              //   title: context.loc.btcPayServer,
              //   iconLeading: AquaIcon.btcpay(),
              //   iconTrailing: AquaIcon.chevronForward(
              //     size: 18,
              //     color: context.aquaColors.textSecondary,
              //   ),
              //   onTap: () {},
              // ),
              // const SizedBox(height: 1.0),
              //Anchor - Export & Share Logs
              AquaListItem(
                title: context.loc.exportAndShareLogs,
                iconLeading: AquaIcon.export(
                  size: 24,
                  color: context.aquaColors.textSecondary,
                ),
                iconTrailing: AquaIcon.chevronForward(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
                onTap: () => ref.read(exportLogsProvider.notifier).export(
                      sharePositionOrigin: context.sharePositionOrigin,
                    ),
              ),
              const SizedBox(height: 1.0),
              if (experimentalFeaturesEnabled) ...[
                //Anchor - Experimental
                AquaListItem(
                  title: context.loc.experimental,
                  iconLeading: AquaIcon.experimental(
                    size: 24,
                    color: context.aquaColors.textSecondary,
                  ),
                  iconTrailing: AquaIcon.chevronForward(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  onTap: () =>
                      context.push(ExperimentalFeaturesScreen.routeName),
                ),
                const SizedBox(height: 1.0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
