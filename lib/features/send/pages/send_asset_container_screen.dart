import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/pages/pages.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetContainerScreen extends HookConsumerWidget {
  const SendAssetContainerScreen({super.key});

  static const routeName = '/sendAssetContainerScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as SendAssetArguments;

    // watch to keep providers alive
    final initializationState = ref.watch(initializationProvider(arguments));
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);
    final amount = ref.watch(userEnteredAmountProvider);
    final lnurlParseResult = ref.watch(lnurlParseResultProvider);
    final addressError = ref.watch(sendAmountErrorProvider);
    final amountError = ref.watch(sendAmountErrorProvider);
    final insufficientBalance = ref.watch(insufficientBalanceProvider);
    final network = asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;
    final feeRates =
        ref.watch(fetchedFeeRatesPerVByteProvider(network)).asData?.value;
    final userSelectedFeeAsset = ref.watch(userSelectedFeeAssetProvider);
    final userSelectedFeeRatePerVByte =
        ref.watch(userSelectedFeeRatePerVByteProvider);
    final userEnteredAmountIsFiat = ref.watch(isFiatInputProvider);
    final useAllFunds = ref.watch(useAllFundsProvider);

    logger.d(
        "[Send] send container - asset: $asset - address: $address - amount: $amount");
    logger.d(
        "[Send] send container - - addressError: $addressError - amountError: $amountError");
    logger.d(
        "[Send] send container - insufficientBalance: $insufficientBalance - feeRates: $feeRates - userSelectedFeeAsset: $userSelectedFeeAsset - userSelectedFeeRatePerVByte: ${userSelectedFeeRatePerVByte?.priority.toString()} - userEnteredAmountIsFiat: $userEnteredAmountIsFiat - useAllFunds: $useAllFunds");
    logger.d("[Send] send container - lnurlParseResult: $lnurlParseResult");

    useEffect(() {
      Future.microtask(() {
        ref.read(initializationProvider(arguments).notifier).initialize();
      });
      return null;
    }, []);

    useEffect(() {
      Future.microtask(() {
        // NOTE: Can switch on error type here to handle other errors
        if (initializationState is AsyncError) {
          final errorMessage = (initializationState.error as ExceptionLocalized)
              .toLocalizedString(context);
          showErrorDialog(context, errorMessage, shouldPopScreen: true);
        }
      });
      return null;
    }, [initializationState]);

    return initializationState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text(context.loc.genericErrorMessage)),
      ),
      data: (_) => switchScreen(context, arguments),
    );
  }

  Widget switchScreen(BuildContext context, SendAssetArguments arguments) {
    // Use the arguments to determine which screen to display
    switch (arguments.startScreen) {
      case SendAssetStartScreen.addressScreen:
        return SendAssetAddressScreen(arguments: arguments);
      case SendAssetStartScreen.amountScreen:
        return SendAssetAmountScreen(arguments: arguments);
      case SendAssetStartScreen.reviewScreen:
        return SendAssetReviewScreen(arguments: arguments);
      default:
        return SendAssetAddressScreen(arguments: arguments);
    }
  }

  void showErrorDialog(BuildContext context, String errorMessage,
      {bool shouldPopScreen = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<CustomAlertDialog>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomAlertDialog(
          onWillPop: () async => false,
          title: context.loc.unknownErrorTitle,
          subtitle: errorMessage,
          controlWidgets: [
            Expanded(
              child: ElevatedButton(
                child: Text(context.loc.genericOk),
                onPressed: () {
                  if (shouldPopScreen) {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
