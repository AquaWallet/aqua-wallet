import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
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

class ReceiveAssetScreen extends HookConsumerWidget {
  const ReceiveAssetScreen({super.key});

  static const routeName = '/receiveAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // asset (layerTwo option only visible for lightning and lbtc)
    final asset = useState(ModalRoute.of(context)?.settings.arguments as Asset);
    final errorMessage = useState<String?>(null);

    final isDirectPegInEnabled =
        ref.watch(prefsProvider.select((p) => p.isDirectPegInEnabled));
    final boltzUiState = ref.watch(boltzReverseSwapProvider);
    final boltzOrder = useMemoized(
      () => boltzUiState.mapOrNull(qrCode: (s) => s.swap),
      [boltzUiState],
    );

    final sideshiftOrder = ref.watch(sideshiftPendingOrderProvider);

    final amountForBip21 =
        ref.watch(receiveAssetAmountForBip21Provider(asset.value));
    final amountAsDecimal =
        ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));
    final address = ref
            .watch(receiveAssetAddressProvider((asset.value, amountAsDecimal)))
            .asData
            ?.value ??
        '';

    final enableShareButton = useMemoized(() {
      return (asset.value.isLightning && boltzOrder == null) ||
          (asset.value.isSideshift && sideshiftOrder == null);
    }, [asset.value, boltzOrder, sideshiftOrder]);

    // ANCHOR: Boltz
    final showGenerateButton = useMemoized(
      () => asset.value.isLightning && boltzUiState.isAmountEntry,
      [asset.value, boltzUiState],
    );

    final generateInvoice = useCallback(() {
      if (context.mounted) {
        if (amountAsDecimal < Decimal.fromInt(boltzMin)) {
          ref.read(boltzReverseSwapUiErrorProvider.notifier).state =
              context.loc.boltzMinAmountError(boltzMin);
          return;
        } else if (amountAsDecimal > Decimal.fromInt(boltzMax)) {
          ref.read(boltzReverseSwapUiErrorProvider.notifier).state =
              context.loc.boltzMaxAmountError(boltzMax);
          return;
        }
        ref.read(boltzReverseSwapProvider.notifier).create(amountAsDecimal);
      }
    }, [amountAsDecimal]);

    if (boltzOrder != null) {
      // listen for boltz claim to show lightning success screen
      ref.listen(boltzSwapStatusProvider(boltzOrder.id), (_, event) async {
        final status = event.value?.status;
        logger.d('[Receive] Boltz Swap Status: $status');
        if (status?.isSuccess == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            errorMessage.value = null;
            Navigator.of(context).pushReplacementNamed(
              LightningTransactionSuccessScreen.routeName,
              arguments: LightningSuccessArguments.receive(
                satoshiAmount: boltzOrder.outAmount,
              ),
            );
          });
        }
      });

      // listen for boltz-to-boltz receives to show lightning success screen
      ref.listen<AsyncValue<List<String>?>>(
          boltzToBoltzReceiveProvider(boltzOrder.id), (_, event) {
        event.whenData((txs) {
          if (txs != null && txs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              errorMessage.value = null;
              Navigator.of(context).pushReplacementNamed(
                LightningTransactionSuccessScreen.routeName,
                arguments: LightningSuccessArguments.receive(
                  satoshiAmount: boltzOrder.outAmount,
                ),
              );
            });
          }
        });
      });
    }

    // ANCHOR: Sideshift
    final handleSideshiftError = useCallback((Object e) {
      final error = (e is ExceptionLocalized)
          ? e.toLocalizedString(context)
          : context.loc.sideshiftGenericError;

      if (e is NoPermissionsException) {
        errorMessage.value = error;
      } else {
        context.showErrorSnackbar(error);
      }
    });

    useEffect(() {
      if (!asset.value.isAnyAltUsdt) {
        return null;
      }

      // clear pending order
      final sideshiftProvider = ref.read(sideshiftOrderProvider);
      sideshiftProvider.setPendingOrder(null);

      // get asset
      final assetPair = SideshiftAssetPair(
        from: asset.value == Asset.usdtEth()
            ? SideshiftAsset.usdtEth()
            : SideshiftAsset.usdtTron(),
        to: SideshiftAsset.usdtLiquid(),
      );

      // setup order
      ref
          .read(sideshiftSetupProvider(assetPair))
          .setupSideshiftOrder()
          .listen((event) {
        debugPrint('[Receive] Sideshift Order Status: ${event.asData?.value}');
        event.when(
          data: (value) {
            if (context.mounted) {
              ref
                  .read(sideshiftOrderProvider)
                  .placeReceiveOrder(
                      deliverAsset: assetPair.from, receiveAsset: assetPair.to)
                  .catchError(handleSideshiftError);
            }
          },
          loading: () {},
          error: (e, st) => handleSideshiftError(e),
        );
      });

      final sideshiftOrder = ref.watch(sideshiftPendingOrderProvider);
      logger.d("[Receive][SideShift] Pending order: ${sideshiftOrder?.id}");

      // inProgressOrderProvider caches a more complete order, so watch that as well
      ref.listen(inProgressOrderProvider, (_, inProgressOrder) {
        logger.d(
            "[Receive][SideShift] In Progress order: ${inProgressOrder?.id} - deposit address: ${inProgressOrder?.depositAddress} - settle address: ${inProgressOrder?.settleAddress}");
      });
      return sideshiftProvider.setShiftCurrentOrderStreamStop;
    }, [asset.value]);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        logger.d('[Navigation] onWillPop in ReceiveAssetScreen called');
        ref.invalidate(receiveAssetAddressProvider);
        ref.invalidate(receiveAssetAmountProvider);
        ref.read(sideshiftOrderProvider).stopAllStreams();
      },
      child: Scaffold(
        appBar: AquaAppBar(
          title: context.loc.receiveAssetScreenTitle,
          iconBackgroundColor:
              Theme.of(context).colors.addressFieldContainerBackgroundColor,
          showActionButton: false,
        ),
        bottomNavigationBar: showGenerateButton
            ? Container(
                height: 50.h,
                margin: EdgeInsets.only(
                  left: 30.w,
                  top: 12.h,
                  right: 30.w,
                  bottom: 48.h,
                ),
                child: AquaElevatedButton(
                  onPressed: generateInvoice,
                  child: Text(context.loc.boltzGenerateInvoice),
                ),
              )
            : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: 14.h, bottom: 32.h),
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
                    boltzUiState.isLightningView) ...[
                  ReceiveLightningView(asset: asset.value),
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
                  //ANCHOR - Direct Peg-In Button
                  if (asset.value.isLBTC && isDirectPegInEnabled) ...[
                    const _DirectPegInButton(),
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
                            isEnabled: enableShareButton,
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectPegInButton extends StatelessWidget {
  const _DirectPegInButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      child: OutlinedButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(DirectPegInScreen.routeName),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onBackground,
          fixedSize: Size(double.maxFinite, 38.h),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          side: BorderSide(
            width: 2.r,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Text(context.loc.receiveAssetScreenDirectPegIn),
      ),
    );
  }
}
