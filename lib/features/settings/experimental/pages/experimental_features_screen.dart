import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
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
    final throwAquaBroadcastErrorEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.throwAquaBroadcastErrorEnabled));
    final forceAquaNodeNotSyncedEnabled = ref.watch(
        featureFlagsProvider.select((p) => p.forceAquaNodeNotSyncedEnabled));
    final isMultiOnrampsEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.multipleOnramps));
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));
    final isStatusIndicatorEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.statusIndicator));
    final isLnurlWithdrawEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.lnurlWithdrawEnabled));
    final isDatabaseExportEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.dbExportEnabled));
    final isSeedQrEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.seedQrEnabled));
    final myFirstBitcoinEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.myFirstBitcoinEnabled));

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
                  Navigator.of(context).pop();
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
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
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
          SizedBox(height: 16.h),
          //ANCHOR: Multi On-Ramps
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsMultiOnramps,
            assetName: Svgs.marketplaceRemittance,
            value: isMultiOnrampsEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.multipleOnramps,
                      currentValue: isMultiOnrampsEnabled,
                    ),
          ),
          SizedBox(height: 16.h),
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
          SizedBox(height: 16.h),
          //ANCHOR: LNUrl Withdraw
          MenuItemWidget.switchItem(
            context: context,
            title: context.loc.expFeaturesScreenItemsLnurlWithdraw,
            assetName: Svgs.marketplaceBankings,
            value: isLnurlWithdrawEnabled,
            onPressed: () =>
                ref.read(featureFlagsProvider.notifier).toggleFeatureFlag(
                      key: PrefKeys.lnurlWithdrawEnabled,
                      currentValue: isLnurlWithdrawEnabled,
                    ),
          ),
          SizedBox(height: 16.h),
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
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

          //ANCHOR: Test Features
          Padding(
            padding: EdgeInsets.only(top: 32.h),
            child: Text(
              context.loc.testSettingsScreenSectionTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

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
          SizedBox(height: 16.h),

          // Debug Mode Only
          if (kDebugMode) ...[
            Padding(
              padding: EdgeInsets.only(top: 32.h),
              child: Text(
                context.loc.expFeaturesScreenSectionDebugMode,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            //ANCHOR - Databse export and import
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
            SizedBox(height: 16.h),
            //ANCHOR - Initiate export txn db flow
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.outgoing,
              color: context.colorScheme.onBackground,
              title: context.loc.testTransactionDatabaseExport,
              isEnabled: isDatabaseExportEnabled,
              onPressed: ref
                  .read(exportTransactionDatabaseProvider.notifier)
                  .requestConfirmation,
            ),
            SizedBox(height: 16.h),
            //ANCHOR - Initiate import txn db flow
            MenuItemWidget.arrow(
              context: context,
              assetName: Svgs.incoming,
              color: context.colorScheme.onBackground,
              title: context.loc.testTransactionDatabaseImport,
              isEnabled: isDatabaseExportEnabled,
              onPressed: ref
                  .read(experimentalRestoreTransactionsProvider.notifier)
                  .checkForStatus,
            ),
            SizedBox(height: 16.h),
            //ANCHOR - Clear all ghost transactions
            MenuItemWidget(
              title: context.loc.expFeaturesScreenItemsClearGhostTxns,
              color: Theme.of(context).colorScheme.onBackground,
              assetName: Svgs.removeWallet,
              onPressed: ref
                  .read(transactionStorageProvider.notifier)
                  .clearGhostTransactions,
            ),
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }
}
