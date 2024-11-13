import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/exchange_rate/providers/exchange_rate_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class SendAssetAmountScreen extends HookConsumerWidget {
  const SendAssetAmountScreen({super.key, this.arguments});

  static const routeName = '/sendAssetAmountScreen';

  final SendAssetArguments? arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

    // setup
    final disableUI = useState<bool>(true);
    final error = ref.watch(sendAmountErrorProvider);
    final isSpinnerVisible = useState<bool>(true);

    // asset, address, amount
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);
    final amount = ref.watch(userEnteredAmountProvider);
    final lnurlParseResult = ref.watch(lnurlParseResultProvider);
    final lnurlPayParams = lnurlParseResult?.payParams;
    final isLightningFromInvoice = asset.isLightning && lnurlPayParams == null;
    final isLnurlPayFixedAmount =
        lnurlPayParams != null && lnurlPayParams.isFixedAmount;

    // balance
    final assetBalanceInSats =
        ref.watch(getBalanceProvider(asset)).asData?.value;
    final assetBalanceDisplay =
        ref.watch(formatterProvider).formatAssetAmountDirect(
              amount: assetBalanceInSats ?? 0,
              precision: asset.precision,
            );
    final assetBalanceFiatDisplay = ref
            .watch(satsToFiatDisplayWithSymbolProvider(assetBalanceInSats ?? 0))
            .asData
            ?.value ??
        '-';

    // min/max
    final (sendMin, sendMax) =
        ref.watch(userEnteredAmountProvider.notifier).sendMinMax();

    // use all funds
    final useAllFunds = ref.watch(useAllFundsProvider);

    // amount controller
    final initialAmount = asset.isLightning
        ? amount?.toInt()
        : amount; //TODO: hack until we have a unified amount display
    final amountInputController =
        useTextEditingController(text: (initialAmount ?? '').toString());
    final disableAmountField = useAllFunds ||
        isLightningFromInvoice ||
        isLnurlPayFixedAmount ||
        disableUI.value == true;

    // asset <> fiat toggle
    final isFiatInput = ref.watch(isFiatInputProvider);

    ref.listen(isFiatInputProvider, (_, value) {
      logger.d("[Send][Amount] isFiatInputProvider onChanged: $value");
      amountInputController.clear();
    });

    // amount in fiat
    final conversionToFiatWithSymbolDisplay =
        ref.watch(amountConvertedToFiatWithSymbolDisplay).asData?.value;
    final conversionToCryptoDisplay = ref.watch(amountConvertedToCryptoDisplay);

    // setup
    ref.listen(sendAssetAmountSetupProvider, (_, setup) {
      if (setup.asData?.value == true) {
        disableUI.value = false;
        isSpinnerVisible.value = false;
      }
    });

    // show a modal telling the user they don't have enough funds
    final insufficientFundsModalShown = useState<bool>(false);
    final showInsufficientFundsModal =
        useCallback((InsufficientFundsType type) {
      if (!insufficientFundsModalShown.value) {
        insufficientFundsModalShown.value = true;
        Future.microtask(() => showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.r),
                topRight: Radius.circular(30.r),
              ),
            ),
            constraints: BoxConstraints(
              maxHeight: context.adaptiveDouble(
                mobile: 0.4.sh,
                tablet: 0.2.sh,
              ),
            ),
            builder: (_) => InsufficientBalanceSheet(type: type)));
      }
    }, []);

    if (error is AmountParsingException &&
        error.type == AmountParsingExceptionType.notEnoughFundsForFee) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showInsufficientFundsModal(InsufficientFundsType.fee);
      });
    }

    //TODO: Temp until we have amount display widget with intl formatter
    final numberFormatter = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.sendAssetScreenTitle,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.inverseSurfaceColor,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
      ),
      resizeToAvoidBottomInset:
          false, // Make sure the Continue button is behind the keyboard
      backgroundColor: Theme.of(context).colors.inverseSurfaceColor,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Logo
            AssetIcon(
              assetId: asset.id,
              assetLogoUrl: asset.logoUrl,
              size: 60.r,
            ),
            SizedBox(height: 20.h),

            //ANCHOR - Balance Amount & Symbol
            Text(
              "$assetBalanceDisplay ${asset.ticker}",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 14.h),

            //ANCHOR - Balance USD Equivalent
            if (asset.shouldShowConversionOnSend) ...[
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colors.usdCenterPillBackgroundColor,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                child: Text(
                  assetBalanceFiatDisplay,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
            SizedBox(height: 40.h),

            //ANCHOR - Amount Input
            SendAssetAmountInput(
                controller: amountInputController,
                symbol: isFiatInput ? currentRate.currency.value : asset.ticker,
                onChanged: (String value) {
                  logger.d(
                      "[Send][Amount] send amount screen - amountInputController onChanged: $value");
                  // Reset useAllFunds when user types in a new amount
                  if (useAllFunds) {
                    ref
                        .read(useAllFundsProvider.notifier)
                        .setUseAllFunds(false);
                  }
                  final withoutCommas = value.replaceAll(',', '');
                  ref
                      .read(userEnteredAmountProvider.notifier)
                      .updateAmount(Decimal.tryParse(withoutCommas));
                },
                onCurrencyTypeToggle: () async {
                  // set new state
                  final isFiatNewValue = !ref.read(isFiatInputProvider);
                  ref.read(isFiatInputProvider.notifier).state = isFiatNewValue;
                },
                allowUsdToggle: asset.shouldAllowUsdToggleOnSend,
                disabled: disableAmountField,
                precision: asset.precision),

            SizedBox(height: 2.h),

            //ANCHOR - Min/Max Range Panel
            if (asset.isSideshift) ...{
              SideshiftMinMaxPanel(asset: ref.watch(sendAssetProvider))
            } else if (asset.isLightning) ...{
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("≈ $conversionToFiatWithSymbolDisplay",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (!isLnurlPayFixedAmount) ...[
                SizedBox(height: 24.h),
                Row(
                  children: <Widget>[
                    Text(
                      '${context.loc.min}: ${numberFormatter.format(sendMin)} sats',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${context.loc.max}: ${numberFormatter.format(sendMax)} sats',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            } else ...{
              //ANCHOR - Conversion + Use All Funds Row
              SizedBox(
                height: 60.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (error != null) ...{
                      Text(error.toLocalizedString(context),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.error))
                    }
                    //ANCHOR - Conversion to fiat
                    else if (conversionToFiatWithSymbolDisplay != null &&
                        asset.shouldShowConversionOnSend) ...{
                      Text("≈ $conversionToFiatWithSymbolDisplay",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    }
                    //ANCHOR - Conversion to crypto
                    else if (isFiatInput &&
                        conversionToCryptoDisplay != null &&
                        asset.shouldShowConversionOnSend) ...{
                      Text("≈ $conversionToCryptoDisplay ${asset.ticker}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    },
                    const Spacer(),
                    //ANCHOR - Use All Funds Button
                    //TODO: Temp disable the "Used all funds" button if `isUsdInput` because the logic is unnecessary complex without a refactor of how we calculate our amounts
                    if (asset.shouldShowUseAllFundsButton && !isFiatInput) ...[
                      SendAssetMaxButton(
                        isSelected: useAllFunds,
                        onPressed: disableUI.value == true
                            ? null
                            : () {
                                ref
                                    .read(useAllFundsProvider.notifier)
                                    .setUseAllFunds(!useAllFunds);
                                final amountDisplay = isFiatInput
                                    ? assetBalanceFiatDisplay
                                    : assetBalanceDisplay;
                                amountInputController.text = amountDisplay;
                              },
                      ),
                    ],
                  ],
                ),
              ),
            },

            const Spacer(),

            //ANCHOR - Spinner
            if (isSpinnerVisible.value) ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ],
            const Spacer(),

            //ANCHOR - Continue Button
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 32.h),
              child: SizedBox(
                width: double.maxFinite,
                child: AquaElevatedButton(
                  onPressed: amount != null &&
                          error == null &&
                          disableUI.value == false
                      ? () {
                          Navigator.of(context).pushNamed(
                            SendAssetReviewScreen.routeName,
                            arguments: SendAssetArguments.fromAsset(asset)
                                .copyWith(
                                    userEnteredAmount: amount, input: address!),
                          );
                        }
                      : null,
                  child: Text(context.loc.sendAssetAmountScreenContinueButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
