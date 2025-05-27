import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/providers/jan3_auth_provider.dart';
import 'package:aqua/features/logger_table/logger_table.dart';
import 'package:aqua/features/settings/debug/debug_database_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/keys/settings_screen_keys.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ExperimentalFeaturesScreen extends HookConsumerWidget
    with RestoreTransactionMixin, ExportTransactionMixin {
  const ExperimentalFeaturesScreen({super.key});

  static const routeName = '/experimentalFeaturesScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTestEnv = ref.watch(envProvider) == Env.testnet;
    final forceBoltzFailEnabled = ref.watch(featureFlagsProvider
        .select((p) => p.forceBoltzFailedNormalSwapEnabled));
    final fakeBroadcastsEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.fakeBroadcastsEnabled));
    final activateSubaccountsEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.activateSubaccountsEnabled));
    final throwAquaBroadcastErrorEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.throwAquaBroadcastErrorEnabled));
    final forceAquaNodeNotSyncedEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.forceAquaNodeNotSyncedEnabled));
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));
    final isStatusIndicatorEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.statusIndicator));
    final isLnurlWithdrawEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.lnurlWithdrawEnabled));
    final pokerChipSweepEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.pokerChipSweepEnabled));
    final isDatabaseExportEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.dbExportEnabled));
    final useChangellyForUSDtSwapsEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.changellyForUSDtSwapsEnabled));
    final isBtcDirectEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.btcDirectEnabled));
    final isSeedQrEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.seedQrEnabled));
    final myFirstBitcoinEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.myFirstBitcoinEnabled));
    final isPayWithMoonEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.payWithMoonEnabled));
    final isCustomElectrumUrlEnabled = ref
        .watch(featureFlagsProvider.select((p) => p.customElectrumUrlEnabled));
    final displayUnit =
        ref.watch(displayUnitsProvider.select((p) => p.currentDisplayUnit));
    final isDebitCardStagingEnabled = ref.watch(
      featureFlagsProvider.select((p) => p.debitCardStagingEnabled),
    );

    final showAlertDialog = useCallback(({
      required String message,
      required VoidCallback onAccept,
    }) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomAlertDialog(
          title: context.loc.information,
          subtitle: message,
          controlWidgets: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  onAccept();
                  context.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(context.loc.ok),
              ),
            ),
          ],
        ),
      );
    });

    final toggleBoltzForceFails = useCallback(() {
      ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
            key: PrefKeys.forceBoltzFailedNormalSwapEnabled,
            currentValue: forceBoltzFailEnabled,
          );
    }, [forceBoltzFailEnabled]);

    listenToExportTransactionHistoryEvents(context, ref);

    listenToRestoreTransactionHistoryEvents(
      context,
      ref,
      useExperimentalProvider: true,
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: AppLocalizations.of(context)!
            .settingsScreenItemExperimentalFeatures,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
        children: [
          //ANCHOR: Notes
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsNotes,
            assetName: Svgs.addNote,
            value: isNotesEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.addNoteEnabled,
                      currentValue: isNotesEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Status Indicator
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsStatusIndicator,
            assetName: Svgs.info,
            value: isStatusIndicatorEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.statusIndicator,
                      currentValue: isStatusIndicatorEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),
          //ANCHOR: LNUrl Withdraw
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.lnUrlWithdraw,
            assetName: Svgs.marketplaceBankings,
            value: isLnurlWithdrawEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.lnurlWithdrawEnabled,
                      currentValue: isLnurlWithdrawEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Poker Chip Sweep
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.pokerchipSweep,
            assetName: Svgs.pokerchipFrameDark,
            value: pokerChipSweepEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.pokerChipSweepEnabled,
                      currentValue: pokerChipSweepEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Seed QR
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsSeedQr,
            assetName: Svgs.qr,
            value: isSeedQrEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.seedQrEnabled,
                      currentValue: isSeedQrEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR - Display Unit
          MenuItemWidget.labeledArrow(
            key: SettingsScreenKeys.settingsDisplayUnitButton,
            context: context,
            assetName: Svgs.displayUnits,
            title: context.loc.displayUnits,
            label: displayUnit.value,
            onPressed: () => context.push(DisplayUnitsSettingsScreen.routeName),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Changelly USDt Swaps
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsChangellyUSDtSwaps,
            assetName: Svgs.walletSend,
            value: useChangellyForUSDtSwapsEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.changellyForUSDtSwapsEnabled,
                      currentValue: useChangellyForUSDtSwapsEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: BTC Direct
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsBtcDirect,
            assetName: Svgs.walletSend,
            value: isBtcDirectEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.btcDirectEnabled,
                      currentValue: isBtcDirectEnabled,
                    ),
          ),

          //ANCHOR: My First Bitcoin
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.marketplaceScreenMyFirstBitcoinButton,
            assetName: Svgs.website,
            value: myFirstBitcoinEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.myFirstBitcoinEnabled,
                      currentValue: myFirstBitcoinEnabled,
                    ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Pay with Moon
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.marketplaceScreenBankingButton,
            assetName: Svgs.marketplaceBankings,
            value: isPayWithMoonEnabled,
            onPressed: () {
              if (isPayWithMoonEnabled) {
                ref.read(jan3AuthProvider.notifier).signOut();
              }
              ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                    key: PrefKeys.payWithMoonEnabled,
                    currentValue: isPayWithMoonEnabled,
                  );
            },
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Watch Only Export
          MenuItemWidget.arrow(
            context: context,
            title: context.loc.watchOnlyScreenTitle,
            assetName: Svgs.tabWallet,
            color: context.colors.onBackground,
            onPressed: () => context.push(WatchOnlyListScreen.routeName),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR - Logs
          MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.history,
              title: context.loc.settingsScreenItemLogs,
              onPressed: () => context.push(LoggerScreen.routeName)),
          const SizedBox(height: 4.0),

          // ANCHOR: Danger Zone
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Text(
              'Danger Zone',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Subaccounts
          MenuItemWidget.arrow(
            context: context,
            title: '${context.loc.subaccountsScreenTitle} (Debug Screen)',
            assetName: Svgs.tabWallet,
            color: Theme.of(context).colorScheme.error,
            onPressed: () => context.push(SubaccountsDebugScreen.routeName),
          ),
          const SizedBox(height: 16.0),

          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsSubaccounts,
            assetName: Svgs.blockExplorer,
            value: isTestEnv,
            onPressed: () => showAlertDialog(
              message: 'Warning: Should only be used with Testnet',
              onAccept: () =>
                  ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                        key: PrefKeys.activateSubaccountsEnabled,
                        currentValue: activateSubaccountsEnabled,
                      ),
            ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Test Features
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Text(
              context.loc.testSettingsScreenSectionTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Debit Card Staging Environment
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsDebitCardStaging,
            assetName: Svgs.marketplaceBankings,
            value: isDebitCardStagingEnabled,
            onPressed: () {
              ref.read(jan3AuthProvider.notifier).signOut();
              ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                    key: PrefKeys.debitCardStagingEnabled,
                    currentValue: isDebitCardStagingEnabled,
                  );
            },
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Testnet
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsTestnetEnv,
            assetName: Svgs.blockExplorer,
            value: isTestEnv,
            onPressed: () => showAlertDialog(
              message: context.loc.expFeaturesScreenMessageTestnetEnv,
              onAccept: () async => await ref
                  .read(envProvider.notifier)
                  .setEnv(isTestEnv ? Env.mainnet : Env.testnet),
            ),
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Boltz Testing
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsForceBoltzFailedNormalSwap,
            assetName: Svgs.lightningBolt,
            value: forceBoltzFailEnabled,
            onPressed: () {
              if (!forceBoltzFailEnabled) {
                showAlertDialog(
                  message:
                      context.loc.expFeaturesScreenMessageBoltzFailedNormalSwap,
                  onAccept: toggleBoltzForceFails,
                );
              } else {
                toggleBoltzForceFails();
              }
            },
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Fake Broadcasts
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.testSettingsScreenItemFakeBroadcast,
            assetName: Svgs.walletSend,
            value: fakeBroadcastsEnabled,
            onPressed: () {
              ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                    key: PrefKeys.fakeBroadcastsEnabled,
                    currentValue: fakeBroadcastsEnabled,
                  );
            },
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Throw Aqua Broadcast Error
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.testSettingsScreenItemThrowAquaBroadcastError,
            assetName: Svgs.walletSend,
            value: throwAquaBroadcastErrorEnabled,
            onPressed: () {
              ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                    key: PrefKeys.throwAquaBroadcastErrorEnabled,
                    currentValue: throwAquaBroadcastErrorEnabled,
                  );
            },
          ),
          const SizedBox(height: 16.0),

          //ANCHOR: Force Aqua Node Not Synced State
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.testSettingsScreenItemForceAquaNodeNotSynced,
            assetName: Svgs.walletSend,
            value: forceAquaNodeNotSyncedEnabled,
            onPressed: () {
              ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                    key: PrefKeys.forceAquaNodeNotSyncedEnabled,
                    currentValue: forceAquaNodeNotSyncedEnabled,
                  );
            },
          ),
          const SizedBox(height: 16.0),

          // Debug Mode Only
          if (kDebugMode) ...[
            Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Text(
                context.loc.expFeaturesScreenSectionDebugMode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Databse export and import
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.history,
              color: context.colors.onBackground,
              title: context.loc.testSettingsScreenDebugDatabaseView,
              isEnabled: true,
              onPressed: () => context.push(DebugDatabaseScreen.routeName),
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Database export and import
            MenuItemWidget.switchItem(
              context: context,
              title: context.loc.testSettingsScreenItemDatabaseExport,
              assetName: Svgs.history,
              value: isDatabaseExportEnabled,
              onPressed: () {
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.dbExportEnabled,
                      currentValue: isDatabaseExportEnabled,
                    );
              },
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Initiate export txn db flow
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.outgoing,
              color: context.colors.onBackground,
              title: context.loc.testTransactionDatabaseExport,
              isEnabled: isDatabaseExportEnabled,
              onPressed: ref
                  .read(exportTransactionDatabaseProvider.notifier)
                  .requestConfirmation,
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Initiate import txn db flow
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.incoming,
              color: context.colors.onBackground,
              title: context.loc.testTransactionDatabaseImport,
              isEnabled: isDatabaseExportEnabled,
              onPressed: ref
                  .read(experimentalRestoreTransactionsProvider.notifier)
                  .checkForStatus,
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Clear all ghost transactions
            MenuItemWidget(
              title: context.loc.expFeaturesScreenItemsClearGhostTxns,
              color: Theme.of(context).colors.onBackground,
              assetName: Svgs.removeWallet,
              onPressed: ref
                  .read(transactionStorageProvider.notifier)
                  .clearGhostTransactions,
            ),
            const SizedBox(height: 16.0),
            //ANCHOR - Enable Custom Electrum URL
            MenuItemWidget.switchItem(
              context: context,
              title: context.loc.expFeaturesScreenItemsEnableElectrumServer,
              assetName: Svgs.blockExplorer,
              value: isCustomElectrumUrlEnabled,
              onPressed: () {
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.customElectrumUrlEnabled,
                      currentValue: isCustomElectrumUrlEnabled,
                    );
              },
            ),
            const SizedBox(height: 16.0),
          ],
        ],
      ),
    );
  }
}
