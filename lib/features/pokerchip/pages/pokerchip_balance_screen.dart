import 'package:aqua/common/common.dart';
import 'package:aqua/data/models/network_amount.dart';
import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/qr_scan/models/qr_scan_arguments.dart';
import 'package:aqua/features/qr_scan/pages/qr_scanner_screen.dart';
import 'package:aqua/features/qr_scan/providers/qr_scan_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

      if (asset == null || !context.mounted) {
        throw ArgumentError(
            'Invalid arguments: asset or externalPrivateKey is null.');
      }

      try {
        final result = await context.push(
          QrScannerScreen.routeName,
          extra: QrScannerArguments(
            asset: asset,
            parseAction: QrScannerParseAction.attemptToParse,
            onSuccessAction: QrOnSuccessNavAction.popBack,
          ),
        ) as SendAssetArguments;

        if (result.externalPrivateKey == null) {
          throw ArgumentError(
              'Invalid arguments: asset or externalPrivateKey is null.');
        }

        final pokerChipState = ref.watch(pokerchipBalanceProvider(address));
        final balance = pokerChipState.valueOrNull?.networkAmount.amount;

        if (balance == null) {
          throw ArgumentError('Invalid arguments: balance or asset is null.');
        }

        final args = SendAssetArguments.fromAsset(asset).copyWith(
          externalPrivateKey: result.externalPrivateKey,
          networkAmount: NetworkAmount(amount: balance, asset: asset),
          transactionType: SendTransactionType.privateKeySweep,
        );

        navigateToSendFlow(args);
      } catch (e) {
        if (!context.mounted) {
          return;
        }
        context
            .showErrorSnackbar('An error occurred while scanning the QR code.');
      }
    }, [asset, navigateToSendFlow]);

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
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.bitcoinChip,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
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
              AquaElevatedButton(
                onPressed: pokerchipBalance.whenOrNull(
                  data: (value) => () =>
                      ref.read(urlLauncherProvider).open(value.explorerLink),
                ),
                child: Text(
                  context.loc.assetTransactionDetailsExplorerButton,
                ),
              ),
              const SizedBox(height: 36.0),

              //ANCHOR: Sweep button (EXPERIMENTAL - NEEDS DESIGN)
              if (pokerchipSweepEnabled && hasBalance)
                AquaElevatedButton(
                  onPressed: sweepFunds,
                  child: Text(context.loc.sweepFunds),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToQrScanner,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
