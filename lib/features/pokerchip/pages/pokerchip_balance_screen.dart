import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/models/network_amount.dart';
import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _logger = CustomLogger(FeatureFlag.pokerchip);

//NOTE: This screen and the rest of the pokerchip views and logic can be abstracted to be re-used for all external private key sweeps
class PokerchipBalanceScreen extends HookConsumerWidget {
  const PokerchipBalanceScreen({super.key, required this.address});

  static const routeName = '/pokerchipBalanceScreen';
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokerchipSweepEnabled =
        ref.read(featureFlagsProvider.select((p) => p.pokerChipSweepEnabled));
    final pokerchipBalance = ref.watch(pokerchipBalanceProvider(address));
    final error = pokerchipBalance.hasError;
    final asset = pokerchipBalance.valueOrNull?.asset;
    final hasBalance = pokerchipBalance.valueOrNull?.balance != '0';

    useEffect(() {
      if (error) {
        Future.microtask(
            () => context.showErrorSnackbar(context.loc.pokerChipBalanceError));
      }
      return null;
    }, [error]);

    final navigateToSendFlow = useCallback((SendAssetArguments args) async {
      await context.push(SendAssetScreen.routeName, extra: args);
    }, []);

    final navigateToQrScanner = useCallback(() async {
      ref.read(qrScanProvider.notifier).restartCamera();

      if (asset == null) {
        _logger.error('Navigate to QR Scanner: Asset is null');
        return;
      }

      final result = await context.push<QrScanState>(
        QrScannerScreen.routeName,
        extra: QrScannerArguments(
          asset: asset,
          parseAction: QrScannerParseAction.attemptToParse,
        ),
      );

      if (result == null) {
        _logger.error('Pokerchip QR Scanned: Result is null');
        return;
      }

      final sendArgs = result.whenOrNull(
        sendAsset: (args) => args,
      );

      if (sendArgs == null || sendArgs.externalPrivateKey == null) {
        _logger.error('Pokerchip QR Scanned: Send args is null');
        return;
      }

      final pokerChipState = ref.read(pokerchipBalanceProvider(address));
      final balance = pokerChipState.valueOrNull?.networkAmount.amount;

      if (balance == null) {
        _logger.error('Pokerchip QR Scanned: Balance is null');
        return;
      }

      final finalArgs = SendAssetArguments.fromAsset(asset).copyWith(
        externalPrivateKey: sendArgs.externalPrivateKey,
        networkAmount: NetworkAmount(amount: balance, asset: asset),
        transactionType: SendTransactionType.privateKeySweep,
      );

      navigateToSendFlow(finalArgs);
    }, [asset, navigateToSendFlow, address, ref]);

    final sweepFunds = useCallback(() {
      final alertModel = CustomAlertDialogUiModel(
        title: context.loc.pokerChipSweepDialogTitle,
        subtitle: context.loc.pokerChipSweepDialogContent,
        buttonTitle: context.loc.proceed,
        onButtonPressed: () {
          context.pop();
          navigateToQrScanner();
        },
        secondaryButtonTitle: context.loc.cancel,
        onSecondaryButtonPressed: () {
          context.pop();
        },
      );

      DialogManager().showDialog(context, alertModel);
    }, [address, asset]);

    return Scaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        title: context.loc.bitcoinChip,
        actions: [
          AquaIcon.close(
            color: context.aquaColors.textSecondary,
            size: 24,
            onTap: () => context.popUntilPath(PokerchipScreen.routeName),
          )
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              //ANCHOR - Pokerchip Info
              pokerchipBalance.when(
                data: (balance) => PokerchipBalanceCard(data: balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              //ANCHOR: Explore button
              AquaButton.primary(
                onPressed: pokerchipBalance.whenOrNull(
                  data: (value) => () =>
                      ref.read(urlLauncherProvider).open(value.explorerLink),
                ),
                text: context.loc.assetTransactionDetailsExplorerButton,
              ),
              const SizedBox(height: 36.0),

              //ANCHOR: Sweep button (EXPERIMENTAL - NEEDS DESIGN)
              if (pokerchipSweepEnabled && hasBalance)
                AquaButton.primary(
                  onPressed: sweepFunds,
                  text: context.loc.sweepFunds,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
