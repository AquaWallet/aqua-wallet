import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/pages/pages.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/features/sideshift/providers/sideshift_send_provider.dart';

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
    ref.watch(sendAddressProvider);
    ref.watch(userEnteredAmountProvider);
    ref.watch(lnurlParseResultProvider);
    ref.watch(sendAmountErrorProvider);
    ref.watch(sendAddressErrorProvider);
    ref.watch(insufficientBalanceProvider);
    ref.watch(fetchedFeeRatesPerVByteProvider(asset.networkType));
    ref.watch(userSelectedFeeAssetProvider);
    ref.watch(userSelectedFeeRatePerVByteProvider);
    ref.watch(isFiatInputProvider);
    ref.watch(useAllFundsProvider);
    ref.watch(sideShiftPendingOrderCacheProvider);

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
    return switch (arguments.startScreen) {
      SendAssetStartScreen.amountScreen =>
        SendAssetAmountScreen(arguments: arguments),
      SendAssetStartScreen.reviewScreen =>
        SendAssetReviewScreen(arguments: arguments),
      _ => SendAssetAddressScreen(arguments: arguments),
    };
  }

  void showErrorDialog(BuildContext context, String errorMessage,
      {bool shouldPopScreen = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<CustomAlertDialog>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomAlertDialog(
          onPopInvoked: (bool value) => false,
          title: context.loc.unknownErrorTitle,
          subtitle: errorMessage,
          controlWidgets: [
            Expanded(
              child: ElevatedButton(
                child: Text(context.loc.ok),
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
