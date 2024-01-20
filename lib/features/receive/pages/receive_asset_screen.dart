import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/sideshift/models/sideshift.dart';
import 'package:aqua/data/provider/sideshift/sideshift_http_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_provider.dart';
import 'package:aqua/features/external/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/receive/widgets/layer_two_toggle_button.dart';
import 'package:aqua/features/receive/widgets/usdt_toggle_button.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/models.dart';

extension BoltzExtension on ReceiveAssetScreen {
  /// Contains the Boltz service logic, which is used for lightning > liquid swaps
  void performBoltzOperations(BuildContext context, WidgetRef ref,
      ValueNotifier<Asset> asset, Function showAmountBottomSheet) {
    if (!asset.value.isLightning) {
      return;
    }

    final boltzService = ref.read(boltzProvider);

    // useEffect to setup boltz service
    useEffect(() {
      // get boltz current order
      final boltzCurrentOrder =
          ref.read(boltzReverseSwapSuccessResponseProvider.notifier).state;

      // setup boltz order status stream
      if (boltzCurrentOrder != null) {
        final _ = boltzService.getSwapStatusStream(boltzCurrentOrder.id).listen(
            (event) =>
                logger.d("[BOLTZ] status stream - event: ${event.toJson()}"));
        return null;
      }

      // check for amount - return and wait for amount if not set
      final amountInSats = ref.read(receiveAssetAmountProvider.notifier).state;
      if (amountInSats == 0) {
        return null;
      }
      if (amountInSats == null) {
        Future.delayed(const Duration(milliseconds: 50), () {
          showAmountBottomSheet(context, ref, asset);
        });
        return null;
      }

      return null;
    }, [asset.value, ref.watch(receiveAssetAmountProvider.notifier).state]);
  }
}

/// Contains the SideShift service logic, which is for `usdt-eth > usdt-liquid` and `usdt-trx > usdt-liquid` for the receive screen
extension SideShiftExtension on State {
  void performSideShiftOperations(
      BuildContext context,
      WidgetRef ref,
      ValueNotifier<Asset> asset,
      Function showAmountBottomSheet,
      ValueNotifier<String?> fixedErrorMessage) {
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
          final error = (e is OrderErrorLocalized)
              ? e.toLocalizedString(context)
              : AppLocalizations.of(context)!.sideshiftGenericError;

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

class ReceiveAssetScreen extends StatefulHookConsumerWidget {
  const ReceiveAssetScreen({super.key});

  static const routeName = '/receiveAssetScreen';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => State();
}

enum BoltzState { loading, generating, processing }

class State extends ConsumerState<ReceiveAssetScreen> {
  late final WebViewController _controller;
  BoltzState? boltzState;
  String? invoice;
  int? boltzLoadingPct;
  BoltzGetPairsResponse? boltzGetPairsResponse;

  Future<void> openBoltz(String amountInSats) async {
    setState(() {
      boltzState = BoltzState.loading;
    });
    final address = await ref.read(liquidProvider).getReceiveAddress();
    boltzGetPairsResponse = await ref.read(boltzGetPairsProvider).asData?.value;

    if (address != null) {
      _controller
          .loadRequest(Uri.parse(urls.boltzWebAppUrl).replace(queryParameters: {
        "embed": "1",
        "assetSend": "LN",
        "assetReceive": "L-BTC",
        "address": address.address,
        "amount": amountInSats.toString()
      }));
    }
  }

  // show bottom sheet
  void showAmountBottomSheet(
      BuildContext context, WidgetRef ref, ValueNotifier<Asset> asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !asset.value
          .isLightning, // disallow dismiss for lightning - use must enter an amount or cancel
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      builder: (_) => ReceiveAmountInputSheet(
        asset: asset.value,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          setState(() {
            if (boltzLoadingPct == null || boltzLoadingPct! < progress) {
              boltzLoadingPct = progress;
            }
          });
        },
      ))
      ..addJavaScriptChannel('Generated',
          onMessageReceived: (msg) => {
                setState(() {
                  boltzState = null;
                })
              })
      ..addJavaScriptChannel('Invoice',
          onMessageReceived: (msg) => {
                setState(() {
                  invoice = msg.message;
                })
              })
      ..addJavaScriptChannel('Processing',
          onMessageReceived: (msg) => {
                setState(() {
                  boltzState = BoltzState.processing;
                })
              })
      ..addJavaScriptChannel('Done', onMessageReceived: (msg) {
        final asset = ModalRoute.of(context)?.settings.arguments as Asset;
        final amount =
            ref.read(receiveAssetAmountForBip21Provider(asset)) ?? '';

        var receiveSatoshiAmount = null;
        if (boltzGetPairsResponse != null) {
          final totalServiceFeeSats = (boltzGetPairsResponse!.reverseClaimFee +
                  boltzGetPairsResponse!.reverseLockupFee +
                  (boltzGetPairsResponse!.reversePercentage /
                      100 *
                      double.parse(amount)))
              .round();
          receiveSatoshiAmount = int.parse(amount) - totalServiceFeeSats;
        }
        Navigator.of(context).pushReplacementNamed(
          LightningTransactionSuccessScreen.routeName,
          arguments: LightningSuccessArguments.receive(
            satoshiAmount: receiveSatoshiAmount,
          ),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    // asset (layerTwo option only visible for lightning and lbtc)
    final asset =
        useState<Asset>(ModalRoute.of(context)?.settings.arguments as Asset);

    // amount
    final amountForBip21 =
        ref.watch(receiveAssetAmountForBip21Provider(asset.value));
    final amountAsDouble =
        ref.watch(parsedAssetAmountAsDoubleProvider(amountForBip21));
    logger.d("[Receive] amount for bip21: $amountForBip21");
    logger.d("[Receive] amount as double: $amountAsDouble");

    // address
    final address = ref
            .watch(receiveAssetAddressProvider(
                asset: asset.value, amount: amountAsDouble))
            .asData
            ?.value ??
        '';
    logger.d("[Receive] receive address: $address");

    // error message
    final errorMessage = useState<String?>(null);
    //extract the raw address
    String rawAddress = address;
    if (address.contains("liquidnetwork")) {
      rawAddress = address
          .split('?')[0]
          .replaceAll("liquidnetwork:", "")
          .replaceAll("/", "");
    } else if (address.contains("bitcoin")) {
      rawAddress =
          address.split('?')[0].replaceAll("bitcoin:", "").replaceAll("/", "");
    }

    if (asset.value.isSideshift) {
      performSideShiftOperations(
          context, ref, asset, showAmountBottomSheet, errorMessage);
    }

    // watch boltz order
    final boltzOrder =
        ref.watch(boltzReverseSwapSuccessResponseProvider.notifier).state;
    final boltzUIState = useState(ReceiveBoltzUIState.enterAmount);

    // watch sideshift order
    final sideshiftOrder = ref.watch(pendingOrderProvider);
    logger.d(
        "[Receive][SideShift] watching pending order: ${sideshiftOrder?.id}");
    // inProgressOrderProvider caches a more complete order, so watch that as well
    ref.listen(inProgressOrderProvider, (_, inProgressOrder) {
      logger.d(
          "[Receive][SideShift] in progress order: ${inProgressOrder?.id} - deposit address: ${inProgressOrder?.depositAddress} - settle address: ${inProgressOrder?.settleAddress}");
    });

    // -
    useEffect(() {
      errorMessage.value = null;

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
          title: AppLocalizations.of(context)!.receiveAssetScreenTitle,
          showActionButton: false,
        ),

        //ANCHOR - Floating Action Button "Generate Invoice" (lightning only)
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: asset.value.isLightning &&
                boltzUIState.value == ReceiveBoltzUIState.enterAmount
            ? Container(
                height: 50.h,
                margin: const EdgeInsets.all(18),
                child: AquaElevatedButton(
                  onPressed: () {
                    if (amountAsDouble < boltzMin) {
                      errorMessage.value = AppLocalizations.of(context)!
                          .boltzMinAmountError(boltzMin);
                      return;
                    } else if (amountAsDouble > boltzMax) {
                      errorMessage.value = AppLocalizations.of(context)!
                          .boltzMaxAmountError(boltzMax);
                      return;
                    }

                    openBoltz(amountForBip21!);
                    boltzUIState.value = ReceiveBoltzUIState.webView;
                  },
                  child:
                      Text(AppLocalizations.of(context)!.boltzGenerateInvoice),
                ),
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
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
                        initialIndex: asset.value.isUsdtLiquid
                            ? UsdtOption.liquid.index
                            : asset.value.isEth
                                ? UsdtOption.eth.index
                                : UsdtOption.trx.index,
                      ),
                    ],

                    //ANCHOR - Receive Amount Input OR Boltz Web View (lightning only)
                    if (asset.value.isLightning) ...[
                      boltzState == BoltzState.processing
                          ? SizedBox(
                              height: 300.h,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      AppLocalizations.of(context)!
                                          .receiveLightningViewProcessingStatusMessage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  SizedBox(
                                    height: 20.h,
                                  ),
                                  const CircularProgressIndicator(),
                                ],
                              ))
                          : ReceiveLightningView(
                              asset: asset.value,
                              boltzUIState: boltzUIState.value,
                              errorMessage: errorMessage.value,
                              state: boltzState,
                              loadingPct: boltzLoadingPct,
                              controller: _controller,
                              invoice: invoice,
                            ),
                    ]

                    //ANCHOR - Main Address Card
                    else ...[
                      SizedBox(height: 24.h),
                      BoxShadowCard(
                        elevation: 4.h,
                        color: Theme.of(context).colorScheme.surface,
                        margin: EdgeInsets.symmetric(horizontal: 28.w),
                        borderRadius: BorderRadius.circular(12.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //ANCHOR - Description
                              SizedBox(height: 12.h),
                              ReceiveAssetAddressLabel(
                                assetName: asset.value.name,
                              ),

                              SizedBox(height: 11.h),
                              //ANCHOR - QR Code
                              ReceiveAssetQrCode(
                                  assetAddress: address,
                                  assetId: asset.value.id,
                                  assetIconUrl: asset.value.logoUrl),
                              SizedBox(height: 21.h),
                              //ANCHOR - Copy Address Button
                              ReceiveAssetCopyAddressButton(
                                address: rawAddress,
                              ),
                              SizedBox(height: 21.h),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 21.h),
                      if (asset.value.isSideshift) ...[
                        const ReceiveShiftInformation(),
                        SizedBox(height: 21.h),
                      ],
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Row(children: [
                          //ANCHOR - Set Amount Button (conditional)
                          if (asset.value.shouldShowAmountInputOnReceive) ...[
                            Expanded(
                              child: _ShadowButton(
                                onPressed: () =>
                                    showAmountBottomSheet(context, ref, asset),
                                svgIcon: Svgs.setAmount,
                                label: AppLocalizations.of(context)!
                                    .receiveAssetScreenSetAmount,
                              ),
                            ),
                            SizedBox(width: 20.w),
                          ],
                          //ANCHOR - Share Button
                          Expanded(
                            child: _ShadowButton(
                              onPressed: (asset.value.isLightning &&
                                          boltzOrder == null) ||
                                      (asset.value.isSideshift &&
                                          sideshiftOrder == null)
                                  ? null
                                  : () => Share.share(address),
                              svgIcon: Svgs.share,
                              label: AppLocalizations.of(context)!
                                  .receiveAssetScreenShare,
                            ),
                          ),
                        ]),
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
                      if (asset.value.isSideshift &&
                          sideshiftOrder == null &&
                          errorMessage.value == null) ...[
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShadowButton extends ConsumerWidget {
  const _ShadowButton({
    Key? key,
    required this.label,
    required this.svgIcon,
    this.onPressed,
  }) : super(key: key);

  final String label;
  final String svgIcon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowElevatedButton(
      onPressed: onPressed,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      background: Theme.of(context).colorScheme.surface,
      foreground: Theme.of(context).colorScheme.onBackground,
      side: !darkMode
          ? BorderSide(
              color: Theme.of(context).colors.roundedButtonOutlineColor,
              width: 1.w,
            )
          : null,
      child: Row(
        children: [
          SvgPicture.asset(
            svgIcon,
            width: 16.r,
            height: 16.r,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onBackground, BlendMode.srcIn),
          ),
          SizedBox(width: 25.w),
          Expanded(
            child: Text(
              label,
            ),
          ),
        ],
      ),
    );
  }
}
