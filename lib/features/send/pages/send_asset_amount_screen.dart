import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/boltz/boltz_provider.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetAmountScreen extends HookConsumerWidget {
  const SendAssetAmountScreen({super.key, this.arguments});

  static const routeName = '/sendAssetAmountScreen';

  final SendAssetArguments? arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // setup
    final disableUI = useState<bool>(true);
    final error = ref.watch(sendAmountErrorProvider);
    final isSpinnerVisible = useState<bool>(true);

    // asset, address, amount
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);
    final amount = ref.watch(userEnteredAmountProvider);
    final lnurlParseResult = ref.watch(lnurlParseResultProvider);

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

    // use all funds
    final useAllFunds = ref.watch(useAllFundsProvider);

    // amount controller
    final initialAmount = asset.isLightning
        ? amount?.toInt()
        : amount; //TODO: hack until we have a unified amount display
    final amountInputController =
        useTextEditingController(text: (initialAmount ?? '').toString());

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
                disabled: useAllFunds ||
                    (asset.isLightning &&
                        lnurlParseResult?.payParams == null) ||
                    disableUI.value == true,
                controller: amountInputController,
                onChanged: (String value) {
                  logger.d(
                      "[Send][Amount] send amount screen - amountInputController onChanged: $value");
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
                symbol: isFiatInput
                    ? context.loc.sendAssetAmountScreenAmountUnitUsd
                    : asset.ticker,
                allowUsdToggle: asset.shouldAllowUsdToggleOnSend),

            SizedBox(height: 2.h),

            //ANCHOR - Min/Max Range Panel
            if (asset.isSideshift) ...{
              const SideshiftMinMaxPanel()
            } else if (asset.isLightning) ...{
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("≈ $conversionToFiatWithSymbolDisplay",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: <Widget>[
                  Text(
                    '${context.loc.min}: $boltzMin sats',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${context.loc.max}: $boltzMax sats',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            } else ...{
              //ANCHOR - Conversion + Use All Funds Row
              SizedBox(
                height: 60.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    //ANCHOR - Conversion to fiat
                    if (conversionToFiatWithSymbolDisplay != null &&
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

            //ANCHOR - Error
            if (error != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child:
                    CustomError(errorMessage: error.toLocalizedString(context)),
              ),
            ],

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
