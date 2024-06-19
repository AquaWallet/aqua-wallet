import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_http_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'models/models.dart';

/// Contains the SideShift service logic, which is for `usdt-eth > usdt-liquid` and `usdt-trx > usdt-liquid` for the receive screen
extension SideShiftExtension on ReceiveAssetScreen {
  void performSideShiftOperations(BuildContext context, WidgetRef ref,
      ValueNotifier<Asset> asset, ValueNotifier<String?> fixedErrorMessage) {
    // useEffect to call sideshift service
    useEffect(() {
      if (asset.value.isSideshift) {
        // clear pending order
        ref.read(sideshiftOrderProvider).setPendingOrder(null);

        // get asset.value
        final SideshiftAssetPair assetPair = SideshiftAssetPair(
          from: asset.value == Asset.usdtEth()
              ? SideshiftAsset.usdtEth()
              : SideshiftAsset.usdtTron(),
          to: SideshiftAsset.usdtLiquid(),
        );

        // handle error
        void handleError(Object e) {
          final error = (e is ExceptionLocalized)
              ? e.toLocalizedString(context)
              : context.loc.sideshiftGenericError;

          if (e is NoPermissionsException) {
            fixedErrorMessage.value = error;
          } else {
            context.showErrorSnackbar(error);
          }
        }

        // setup order
        final sideshift =
            ref.read(sideshiftSetupProvider(assetPair)).setupSideshiftOrder();
        sideshift.listen((event) {
          event.when(
              data: (value) {
                ref
                    .read(sideshiftOrderProvider)
                    .placeReceiveOrder(
                        deliverAsset: assetPair.from,
                        receiveAsset: assetPair.to)
                    .catchError(handleError);
              },
              loading: () {},
              error: (e, st) => handleError(e));
        });
      }

      return () {
        ref.read(sideshiftOrderProvider).setShiftCurrentOrderStreamStop();
      };
    }, [
      asset.value,
    ]);
  }
}

class ReceiveAssetScreen extends HookConsumerWidget {
  const ReceiveAssetScreen({super.key});

  static const routeName = '/receiveAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // asset (layerTwo option only visible for lightning and lbtc)
    final asset =
        useState<Asset>(ModalRoute.of(context)?.settings.arguments as Asset);

    // amount
    final amountForBip21 =
        ref.watch(receiveAssetAmountForBip21Provider(asset.value));
    final amountAsDecimal =
        ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));
    logger.d("[Receive] amount for bip21: $amountForBip21");
    logger.d("[Receive] amount as double: $amountAsDecimal");

    // receive address
    final address = ref
            .watch(receiveAssetAddressProvider((asset.value, amountAsDecimal)))
            .asData
            ?.value ??
        '';
    logger.d("[Receive] receive address: $address");

    // error message
    final errorMessage = useState<String?>(null);

    // boltz ui state
    final boltzUIState = useState(asset.value.isLightning
        ? ReceiveBoltzUIState.loading
        : ReceiveBoltzUIState.inactive);
    BoltzCreateReverseSwapResponse? boltzOrder;

    // boltz create reverse swap
    final createBoltzReverseSwap = useCallback(() async {
      boltzUIState.value = ReceiveBoltzUIState.generatingInvoice;
      if (amountAsDecimal == Decimal.zero) {
        logger.e("[Receive] amount as double is null");
        return;
      }

      ref
          .read(boltzProvider)
          .createReverseSwap(amountAsDecimal.toInt())
          .then((response) {
        boltzUIState.value = ReceiveBoltzUIState.qrCode;
      }).catchError((e) {
        errorMessage.value = e.toString();
      });
    }, [amountAsDecimal]);

    // boltz reverse swap success
    final pushToLightningSuccessScreen = useCallback(() {
      final receiveAmount = ref.read(boltzProvider).getReceiveAmount();
      Navigator.of(context).pushReplacementNamed(
        LightningTransactionSuccessScreen.routeName,
        arguments: LightningSuccessArguments.receive(
          satoshiAmount: receiveAmount,
        ),
      );
    }, []);

    // boltz setup
    if (asset.value.isLightning) {
      final boltzGetPairsResponse =
          ref.watch(boltzGetPairsProvider).asData?.value;

      // change ui state when pairs response is received
      if (boltzGetPairsResponse != null &&
          boltzUIState.value == ReceiveBoltzUIState.loading) {
        boltzUIState.value = ReceiveBoltzUIState.enterAmount;
      }

      // watch order status
      boltzOrder =
          ref.watch(boltzReverseSwapSuccessResponseProvider.notifier).state;
      if (boltzOrder != null) {
        errorMessage.value = null;

        final _ = ref
            .read(boltzProvider)
            .getSwapStatusStream(boltzOrder.id)
            .listen((event) {
          if (event.status.isSuccess) {
            pushToLightningSuccessScreen();
          }
        }, onError: (e) {
          errorMessage.value = e.toString();
        });
      }
    }

    // setup sidehift
    SideshiftOrder? sideshiftOrder;
    final isSideshiftLoading = useState(asset.value.isSideshift);

    if (asset.value.isSideshift) {
      performSideShiftOperations(context, ref, asset, errorMessage);

      sideshiftOrder = ref.watch(pendingOrderProvider);
      logger.d(
          "[Receive][SideShift] watching pending order: ${sideshiftOrder?.id}");
      isSideshiftLoading.value = sideshiftOrder == null;

      // inProgressOrderProvider caches a more complete order, so watch that as well
      ref.listen(inProgressOrderProvider, (_, inProgressOrder) {
        logger.d(
            "[Receive][SideShift] in progress order: ${inProgressOrder?.id} - deposit address: ${inProgressOrder?.depositAddress} - settle address: ${inProgressOrder?.settleAddress}");
      });
    }

    // reset on asset change
    useEffect(() {
      errorMessage.value = null;
      ref.read(receiveAssetAmountProvider.notifier).state = null;
      boltzUIState.value = asset.value.isLightning
          ? ReceiveBoltzUIState.loading
          : ReceiveBoltzUIState.inactive;
      isSideshiftLoading.value = asset.value.isSideshift;

      return null;
    }, [asset.value]);

    return WillPopScope(
      onWillPop: () async {
        logger.d('[Navigation] onWillPop in ReceiveAssetScreen called');
        ref.invalidate(receiveAssetAddressProvider);
        ref.invalidate(receiveAssetAmountProvider);
        ref.read(sideshiftOrderProvider).stopAllStreams();
        return true;
      },
      child: Scaffold(
        appBar: AquaAppBar(
          title: context.loc.receiveAssetScreenTitle,
          iconBackgroundColor:
              Theme.of(context).colors.addressFieldContainerBackgroundColor,
          showActionButton: false,
        ),
        bottomNavigationBar: asset.value.isLightning &&
                boltzUIState.value == ReceiveBoltzUIState.enterAmount
            ? Container(
                height: 50.h,
                margin: EdgeInsets.only(
                    left: 30.w, top: 12.h, right: 30.w, bottom: 48.h),
                child: AquaElevatedButton(
                  onPressed: () {
                    if (amountAsDecimal < Decimal.fromInt(boltzMin)) {
                      errorMessage.value =
                          context.loc.sendMinAmountError(boltzMin);
                      return;
                    } else if (amountAsDecimal > Decimal.fromInt(boltzMax)) {
                      errorMessage.value =
                          context.loc.sendMaxAmountError(boltzMax);
                      return;
                    }

                    createBoltzReverseSwap();
                  },
                  child: Text(context.loc.boltzGenerateInvoice),
                ),
              )
            : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //ANCHOR - LN/LQ Toggle Button
                if (asset.value.isLightning || asset.value.isLBTC) ...[
                  LayerTwoToggleButton(
                    onOptionSelected: (selectedOption) {
                      asset.value = switch (selectedOption) {
                        LayerTwoOption.lightning => Asset.lightning(),
                        LayerTwoOption.lbtc =>
                          ref.read(manageAssetsProvider).lbtcAsset,
                      };
                    },
                    initialIndex: asset.value.isLightning
                        ? LayerTwoOption.lightning.index
                        : LayerTwoOption.lbtc.index,
                  ),
                ],
                //ANCHOR - Usdt Toggle Button
                if (asset.value.isUSDt) ...[
                  UsdtToggleButton(
                    onOptionSelected: (selectedOption) {
                      asset.value = switch (selectedOption) {
                        UsdtOption.liquid =>
                          ref.read(manageAssetsProvider).liquidUsdtAsset,
                        UsdtOption.eth => Asset.usdtEth(),
                        UsdtOption.trx => Asset.usdtTrx(),
                      };
                    },
                    initialIndex: asset.value.usdtOption.index,
                  ),
                ],
                //ANCHOR - Receive Amount Input
                if (asset.value.isLightning &&
                    [
                      ReceiveBoltzUIState.loading,
                      ReceiveBoltzUIState.enterAmount,
                      ReceiveBoltzUIState.generatingInvoice
                    ].contains(boltzUIState.value)) ...[
                  ReceiveLightningView(
                    asset: asset.value,
                    boltzUIState: boltzUIState.value,
                    errorMessage: errorMessage.value,
                  ),
                ]
                //ANCHOR - Main Address Card
                else ...[
                  SizedBox(height: 24.h),
                  ReceiveAssetAddressQrCard(
                    asset: asset.value,
                    address: address,
                  ),
                  //ANCHOR - Sideshift Info Container
                  SizedBox(height: 21.h),
                  if (asset.value.isSideshift) ...[
                    ReceiveShiftInformation(
                      assetNetwork:
                          asset.value.usdtOption.networkLabel(context),
                    ),
                    SizedBox(height: 21.h),
                  ],
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Row(
                      children: [
                        //ANCHOR - Set Amount Button (conditional)
                        if (asset.value.shouldShowAmountInputOnReceive) ...[
                          Expanded(
                            child: ReceiveAssetAmountButton(
                              asset: asset.value,
                            ),
                          ),
                          SizedBox(width: 20.w),
                        ],
                        //ANCHOR - Share Button
                        Flexible(
                          flex: asset.value.shouldShowAmountInputOnReceive
                              ? 0
                              : 1,
                          child: ReceiveAssetAddressShareButton(
                            isEnabled: (asset.value.isLightning &&
                                    boltzOrder == null) ||
                                (asset.value.isSideshift &&
                                    sideshiftOrder == null),
                            isExpanded:
                                !asset.value.shouldShowAmountInputOnReceive,
                            address: address,
                          ),
                        ),
                      ],
                    ),
                  ),
                  //ANCHOR - Fixed Error
                  SizedBox(height: 21.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Column(children: [
                      CustomError(errorMessage: errorMessage.value),
                    ]),
                  ),
                  SizedBox(height: 40.h),
                  //ANCHOR - Spinner
                  if ((isSideshiftLoading.value ||
                          boltzUIState.value == ReceiveBoltzUIState.loading) &&
                      errorMessage.value == null) ...[
                    const CircularProgressIndicator(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
