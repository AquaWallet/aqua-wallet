import 'package:aqua/common/utils/string_extensions.dart';
import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/conversion_provider.dart';
import 'package:aqua/data/provider/fiat_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_http_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/external/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/providers/asset_balance_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Contains the Boltz service logic, which is used for lightning > liquid swaps

extension BoltzSendAssetExtension on SendAssetScreen {
  Future<void> performBoltzOperations(BuildContext context, WidgetRef ref,
      String? address, Function showSpinner) async {
    final asset = ref.read(sendAssetProvider);

    // create swap
    if (asset.isLightning && address != null && address.isNotEmpty) {
      final amount = ref.read(userEnteredAmountProvider);

      // check if swap with that invoice already exists
      final existingSwap = await ref
          .read(boltzDataProvider)
          .getBoltzNormalSwapDataByInvoice(address);

      if (existingSwap != null) {
        ref.read(boltzSwapSuccessResponseProvider.notifier).state =
            existingSwap.response;
        showSpinner(false);

        if (context.mounted) {
          Navigator.of(context).pushNamed(
            SendAssetReviewScreen.routeName,
            arguments: SendAssetArguments.fromAsset(asset).copyWith(
                address: existingSwap.response.address,
                recipientAddress: existingSwap.response.address,
                userEnteredAmount: amount,
                externalServiceTxId: existingSwap.response.id),
          );
        }

        return;
      }

      // call createSwap if none existing
      showSpinner(true);

      ref
          .read(boltzProvider)
          .createSwap(invoice: address, context: context)
          .listen((responseAsyncValue) {
        responseAsyncValue.when(
            data: (response) async {
              logger.d(
                  '[Send][Boltz] SEND UI - SUCCESS createSwap: ${response.toJson()}');
              logger.d(
                  '[Send][Boltz] response expectedAmount: ${response.expectedAmount}');
              logger.d('[Send][Boltz] response address: ${response.address}');

              showSpinner(false);
              Navigator.of(context).pushNamed(SendAssetReviewScreen.routeName,
                  arguments: SendAssetArguments.fromAsset(asset).copyWith(
                    address: response.address,
                    recipientAddress: response.address,
                    userEnteredAmount: amount,
                    externalServiceTxId: response.id,
                  ));
            },
            loading: () {},
            error: (e, st) {
              context.showErrorSnackbar(e.toString().removeBraces());
              showSpinner(false);
            });
      });
    }
  }
}

/// Contains the SideShift service logic, which is for `usdt-liquid > usdt-eth` and `usdt-liquid > usdt-trx` for the send screen
extension SideShiftSendAssetExtension on SendAssetScreen {
  /// Setup the order - check permissions and get pair info
  void setupSideShiftOperations(
      BuildContext context,
      WidgetRef ref,
      ValueNotifier<bool> disableUI,
      ValueNotifier<String?> fixedErrorMessage,
      Function showSpinner) {
    final asset = ref.read(sendAssetProvider);

    // useEffect to call sideshift service
    useEffect(() {
      if (asset.isSideshift) {
        // get pair
        final SideshiftAssetPair assetPair = SideshiftAssetPair(
          from: SideshiftAsset.usdtLiquid(),
          to: asset == Asset.usdtEth()
              ? SideshiftAsset.usdtEth()
              : SideshiftAsset.usdtTron(),
        );

        // setup order
        final sideshift =
            ref.read(sideshiftSetupProvider(assetPair)).setupSideshiftOrder();

        sideshift.listen((event) {
          event.when(
              data: (value) {
                logger.d('[Send][SideShift] setup order');
              },
              loading: () {},
              error: (e, st) {
                final error = (e is OrderErrorLocalized)
                    ? e.toLocalizedString(context)
                    : AppLocalizations.of(context)!.sideshiftGenericError;

                if (e is NoPermissionsException) {
                  fixedErrorMessage.value = error;
                  disableUI.value = true;
                } else {
                  context.showErrorSnackbar(error);
                }
              });
        });
      }

      return () {
        ref.read(sideshiftOrderProvider).setShiftCurrentOrderStreamStop();
      };
    }, [ref.read(sendAssetProvider)]);

    // watch sideshift order and push to next screen when set (continue button starts the order)
    ref.listen(pendingOrderProvider, (_, pendingOrder) {
      final depositAddress = pendingOrder?.depositAddress;
      final amount = ref.read(userEnteredAmountProvider);
      if (pendingOrder != null && depositAddress != null && amount != null) {
        showSpinner(false);

        Navigator.of(context).pushNamed(
          SendAssetReviewScreen.routeName,
          arguments: SendAssetArguments.fromAsset(asset).copyWith(
            address: pendingOrder.depositAddress!,
            userEnteredAmount: amount,
            recipientAddress: pendingOrder.settleAddress,
            externalServiceTxId: pendingOrder.id,
          ),
        );
      }
    });
  }

  /// Start the sideshift fixed order
  Future<void> performSideShiftOperations(
      BuildContext context,
      WidgetRef ref,
      String? address,
      ValueNotifier<bool> disableUI,
      ValueNotifier<String?> fixedErrorMessage,
      Function showSpinner) async {
    final asset = ref.read(sendAssetProvider);

    if (asset.isSideshift) {
      showSpinner(true);

      // get pair
      final SideshiftAssetPair assetPair = SideshiftAssetPair(
        from: SideshiftAsset.usdtLiquid(),
        to: asset == Asset.usdtEth()
            ? SideshiftAsset.usdtEth()
            : SideshiftAsset.usdtTron(),
      );

      // get pair info
      final currentPairInfo =
          ref.read(sideshiftCurrentPairInfoProvider.notifier).state;

      // get refund address
      final refundAddress = await ref.read(liquidProvider).getReceiveAddress();
      logger.d("[Send][Sideshift] refundAddress: $refundAddress");
      if (refundAddress == null) {
        throw Exception('Could not get refund address');
      }

      // start order
      final amount = ref.read(userEnteredAmountProvider);
      ref
          .read(sideshiftOrderProvider)
          .placeSendOrder(
              deliverAsset: assetPair.from,
              receiveAsset: assetPair.to,
              refundAddress: refundAddress.address,
              amount: amount,
              receiveAddress: address,
              exchangeRate: currentPairInfo)
          .catchError((e) {
        final error = (e is OrderErrorLocalized)
            ? e.toLocalizedString(context)
            : AppLocalizations.of(context)!.sideshiftGenericError;

        fixedErrorMessage.value = error;

        showSpinner(false);
      });
    }
  }
}

class SendAssetScreen extends HookConsumerWidget {
  const SendAssetScreen({super.key});

  static const routeName = '/sendAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialArguments =
        ModalRoute.of(context)?.settings.arguments as SendAssetArguments;
    final arguments = useState<SendAssetArguments>(initialArguments);

    // initial state
    useEffect(() {
      Future.microtask(() =>
          ref.read(sendAssetProvider.notifier).state = initialArguments.asset);
      Future.microtask(() => ref
          .read(userEnteredAmountProvider.notifier)
          .state = initialArguments.userEnteredAmount);
      return null;
    }, const []);

    // setup
    final disableUI = useState<bool>(false);
    final fixedErrorMessage = useState<String?>(null);
    final validationError = useState<SendAssetValidationException?>(null);
    final isSpinnerVisible = useState<bool>(false);
    void showSpinner(bool isVisibile) {
      isSpinnerVisible.value = isVisibile;
    }

    // asset
    final asset = ref.watch(sendAssetProvider);

    // balance
    final assetBalanceInSats =
        ref.watch(getBalanceProvider(asset)).asData?.value;
    final assetBalanceDisplay = ref.watch(formatterProvider).formatAssetAmount(
          amount: assetBalanceInSats ?? 0,
          precision: asset.precision,
        );

    final assetBalanceFiatAmount =
        ref.watch(satsToFiatProvider(assetBalanceInSats ?? 0)).asData?.value ??
            '-';

    // use all funds
    final useAllFunds = ref.watch(useAllFundsProvider);

    // asset <> usd toggle
    final isUsdInput = ref.watch(userEnteredAmountIsUsdProvider);

    // amount entered
    final amount = ref.watch(userEnteredAmountProvider);
    final amountInputController = useTextEditingController(
        text: initialArguments.userEnteredAmount?.toString());

    final fromSymbol = isUsdInput
        ? AppLocalizations.of(context)!.sendAssetAmountScreenAmountUnitUsd
        : arguments.value.asset.ticker;

    amountInputController.addListener(() {
      final withoutCommas = amountInputController.text.replaceAll(',', '');
      ref.read(userEnteredAmountProvider.notifier).state =
          double.tryParse(withoutCommas);
    });

    // amount in sats
    final amountInSats = amount != null
        ? ref.read(formatterProvider).parseAssetAmountDirect(
            amount: amount.toString(), precision: asset.precision)
        : null;
    // amount in fiat
    final amountInFiat = amountInSats != null && !isUsdInput
        ? ref.watch(satsToFiatProvider(amountInSats)).asData?.value
        : null;

    final amountInCrypto = amount != null && isUsdInput
        ? ref.watch(conversionFiatProvider((asset, amount)))
        : null;
    final fiatAmountInSats = amountInCrypto != null
        ? ref.read(formatterProvider).parseAssetAmountDirect(
            amount: amountInCrypto, precision: asset.precision)
        : null;

    final fiatToAssetAmountConverted = fiatAmountInSats != null
        ? double.tryParse(ref.read(formatterProvider).formatAssetAmount(
              amount: fiatAmountInSats,
              precision: asset.precision,
            ))
        : null;

    // addresss
    final address = useState<String?>(arguments.value.address);
    final addressInputController =
        useTextEditingController(text: initialArguments.address);
    addressInputController.addListener(() {
      address.value = addressInputController.text;
    });

    // validate inputs
    ref
        .watch(sendAssetValidationProvider(
            params: SendAssetValidationParams(
                asset: asset,
                address: address.value,
                amount: isUsdInput ? fiatAmountInSats : amountInSats,
                balance: assetBalanceInSats)))
        .when(
          data: (_) => validationError.value = null,
          loading: () {},
          error: (error, _) {
            if (error is SendAssetValidationException) {
              validationError.value = error;
            }
          },
        );

    // parse address field input to get address and amount
    if (address.value != null && address.value!.isNotEmpty) {
      try {
        final parsedAddress = ref
            .read(addressParserProvider)
            .parseAddress(input: address.value!, asset: asset);

        if (parsedAddress != null) {
          address.value = parsedAddress.address;
          addressInputController.text = parsedAddress.address;
        }

        if (parsedAddress != null && parsedAddress.amount != null) {
          ref.read(userEnteredAmountProvider.notifier).state =
              parsedAddress.amount;
          amountInputController.text = asset.isLightning
              ? parsedAddress.amount!.toInt().toString()
              : parsedAddress.amount.toString();
        }
      } catch (e) {
        logger.e(e);
      }
    }

    // extract asset,address and amount values values from text field or qr input
    void extractAddressInputValues(SendAssetArguments result) {
      // reset asset
      // there is one except that if the scanned asset resolves as l-btc because a plain liquid address was scanned, and we are already on a liquid asset, then don't reset the asset to l-btc. Stay on the more specific liquid asset|
      final originalAssetIsLiquidButNotLBTC =
          ref.read(manageAssetsProvider).isLiquidButNotLBTC(asset);
      final scannedAssetResolvesToLBTC =
          ref.read(manageAssetsProvider).isLBTC(result.asset);
      if (originalAssetIsLiquidButNotLBTC && scannedAssetResolvesToLBTC) {
        // do nothing - stay on original liquid asset
      } else {
        arguments.value = SendAssetArguments.fromAsset(result.asset);
        ref.read(sendAssetProvider.notifier).state = result.asset;
      }

      address.value = result.address;
      addressInputController.text = result.address;

      ref.read(userEnteredAmountProvider.notifier).state =
          result.userEnteredAmount;
      amountInputController.text = (result.userEnteredAmount ?? '').toString();
    }

    // setup sideshift if needed
    if (asset.isSideshift) {
      setupSideShiftOperations(
          context, ref, disableUI, fixedErrorMessage, showSpinner);
    }

    return WillPopScope(
      onWillPop: () async {
        logger.d('[Navigation] onWillPop in SendAssetScreen called');
        ref.read(sideshiftOrderProvider).stopAllStreams();
        return true;
      },
      child: Scaffold(
        appBar: AquaAppBar(
          title: AppLocalizations.of(context)!.sendAssetScreenTitle,
          showActionButton: false,
          backgroundColor: Theme.of(context).colors.altScreenBackground,
          iconBackgroundColor: Theme.of(context).colors.altScreenSurface,
        ),
        backgroundColor: Theme.of(context).colors.altScreenBackground,
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
                    color:
                        Theme.of(context).colors.usdContainerSendRecieveAssets,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
                  child: Text(
                    assetBalanceFiatAmount,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
              SizedBox(height: 40.h),
              //ANCHOR - Address Input
              AddressInputView(
                hintText: asset.isLightning
                    ? AppLocalizations.of(context)!
                        .sendAssetScreenLightningInputHint
                    : AppLocalizations.of(context)!.sendAssetScreenInputHint,
                disabled: disableUI.value == true,
                controller: addressInputController,
                onPressed: () async {
                  //TODO: Change logic for text input
                  SendAssetArguments result = await Navigator.of(context)
                          .pushNamed(
                              QrScannerScreen.routeName,
                              arguments: QrScannerScreenArguments(
                                  asset: asset,
                                  parseAddress: true,
                                  network: arguments.value.network,
                                  onSuccessAction: QrOnSuccessAction.pull))
                      as SendAssetArguments;

                  extractAddressInputValues(result);
                },
              ),
              SizedBox(height: 20.h),
              //ANCHOR - Amount Input
              SendAssetAmountInput(
                  disabled: useAllFunds ||
                      asset.shouldDisableEditAmountOnSend ||
                      disableUI.value == true,
                  controller: amountInputController,
                  symbol: fromSymbol,
                  allowUsdToggle: asset.shouldAllowUsdToggleOnSend),

              SizedBox(height: 18.h),
              if (asset.isSideshift) ...{
                const AssetAmountRangePanel()
              } else if (asset.isLightning) ...{
                Row(
                  children: <Widget>[
                    Text(
                      '${AppLocalizations.of(context)!.min}: $boltzMinString sats',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${AppLocalizations.of(context)!.max}: $boltzMaxString sats',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                )
              } else ...{
                Row(
                  children: [
                    //ANCHOR - Conversion
                    if (amountInFiat != null &&
                        asset.shouldShowConversionOnSend) ...{
                      Text("≈ $amountInFiat",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    } else if (fiatToAssetAmountConverted != null) ...{
                      Text(
                          "≈ $fiatToAssetAmountConverted ${arguments.value.symbol}"),
                    },
                    const Spacer(),
                    //ANCHOR - Use All Funds Button
                    //TODO: Temp disable the "Used all funds" button if `isUsdInput` because the logic is unnecessary complex without a refactor of how we calculate our amounts
                    if (asset.shouldShowUseAllFundsButton && !isUsdInput) ...[
                      TextButton(
                        onPressed: disableUI.value == true
                            ? null
                            : () {
                                ref.read(useAllFundsProvider.notifier).state =
                                    !useAllFunds;
                                if (useAllFunds == true) {
                                  // reset amount input
                                  amountInputController.text = '';
                                } else {
                                  amountInputController.text = isUsdInput
                                      ? assetBalanceFiatAmount
                                      : assetBalanceDisplay;
                                }
                              },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                            side: useAllFunds
                                ? BorderSide.none
                                : BorderSide(
                                    color: Theme.of(context)
                                        .colors
                                        .roundedButtonOutlineColor,
                                    width: 2.w,
                                  ),
                          ),
                          foregroundColor: useAllFunds
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onBackground,
                          backgroundColor: useAllFunds
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        child: Text(AppLocalizations.of(context)!
                            .sendAssetScreenUseAllFundsButton),
                      ),
                    ],
                  ],
                )
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
              //ANCHOR - Fixed Error
              CustomError(errorMessage: fixedErrorMessage.value),
              SizedBox(height: 20.h),
              //ANCHOR - Button
              SizedBox(
                width: double.maxFinite,
                child: AquaElevatedButton(
                  onPressed:
                      validationError.value == null && disableUI.value == false
                          ? () {
                              // call boltz if lightning
                              if (asset.isLightning) {
                                performBoltzOperations(
                                    context, ref, address.value, showSpinner);
                              }
                              // call sideshift
                              else if (asset.isSideshift) {
                                performSideShiftOperations(
                                    context,
                                    ref,
                                    address.value,
                                    disableUI,
                                    fixedErrorMessage,
                                    showSpinner);
                              }
                              // otherwise push to next screen
                              else {
                                Navigator.of(context).pushNamed(
                                  SendAssetReviewScreen.routeName,
                                  arguments: SendAssetArguments.fromAsset(asset)
                                      .copyWith(
                                          userEnteredAmount: isUsdInput
                                              ? fiatToAssetAmountConverted
                                              : amount,
                                          address: address.value!,
                                          recipientAddress: address.value!),
                                );
                              }
                            }
                          : null,
                  child: Text(
                    validationError.value != null
                        ? validationError.value!.toLocalizedString(context)
                        : AppLocalizations.of(context)!
                            .sendAssetAmountScreenContinueButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
