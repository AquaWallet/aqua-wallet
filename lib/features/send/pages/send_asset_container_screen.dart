import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/pages/pages.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetContainerScreen extends HookConsumerWidget {
  const SendAssetContainerScreen({super.key});

  static const routeName = '/sendAssetContainerScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as SendAssetArguments;

    // watch to keep providers alive
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

    // initial state
    final isInitialized = useState(false);
    useEffect(() {
      Future.microtask(() {
        ref.read(sendAssetProvider.notifier).state = arguments.asset;
        ref.read(sendAddressProvider.notifier).state = arguments.input;
        ref
            .read(userEnteredAmountProvider.notifier)
            .updateAmount(arguments.userEnteredAmount);
        ref.read(lnurlParseResultProvider.notifier).state =
            arguments.lnurlParseResult;
        isInitialized.value = true;
      });

      return null;
    }, const []);

    if (!isInitialized.value) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Switch to the appropriate screen after initializing is complete
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
}
