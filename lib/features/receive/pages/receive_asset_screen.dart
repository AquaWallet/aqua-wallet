import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final _kLightningAsset = Asset.lightning();
final _kUsdtEthAsset = Asset.usdtEth();
final _kUsdtTrxAsset = Asset.usdtTrx();

class ReceiveAssetScreen extends HookConsumerWidget {
  const ReceiveAssetScreen({super.key});

  static const routeName = '/receiveAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // asset (layerTwo option only visible for lightning and lbtc)
    final asset = useState(ModalRoute.of(context)?.settings.arguments as Asset);
    final isLightningOrLiquidAsset = useMemoized(
      () => asset.value.isLightning || asset.value.isLBTC,
      [asset.value],
    );
    final lbtcAsset =
        useMemoized(() => ref.read(manageAssetsProvider).lbtcAsset);
    final liquidUsdtAsset =
        useMemoized(() => ref.read(manageAssetsProvider).liquidUsdtAsset);
    final allAssets = useMemoized(() => [
          lbtcAsset,
          liquidUsdtAsset,
          _kLightningAsset,
          _kUsdtEthAsset,
          _kUsdtTrxAsset,
        ]);
    final addressCards = useMemoized(() => {
          for (final asset in allAssets) ...{
            if (asset.isAnyAltUsdt)
              asset.id: ReceiveSideshiftCard(
                key: Key(asset.id),
                asset: asset,
              )
            else
              asset.id: ReceiveAddressCard(
                key: Key(asset.id),
                asset: asset,
              ),
          }
        });

    // NOTE: Keep sideshift receive providers alive for the screen lifecylce
    ref.watch(sideshiftReceiveProvider(_kUsdtTrxAsset));
    ref.watch(sideshiftReceiveProvider(_kUsdtEthAsset));

    final boltzUiState = ref.watch(boltzReverseSwapProvider);
    final boltzOrder = useMemoized(
      () => boltzUiState.mapOrNull(qrCode: (s) => s.swap),
      [boltzUiState],
    );

    final amountForBip21 =
        ref.watch(receiveAssetAmountForBip21Provider(asset.value));
    final amountAsDecimal =
        ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));

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
            Navigator.of(context).pushReplacementNamed(
              LightningTransactionSuccessScreen.routeName,
              arguments: LightningSuccessArguments(
                  satoshiAmount: boltzOrder.outAmount,
                  type: LightningSuccessType.receive,
                  orderId: boltzOrder.id),
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
              Navigator.of(context).pushReplacementNamed(
                LightningTransactionSuccessScreen.routeName,
                arguments: LightningSuccessArguments(
                    satoshiAmount: boltzOrder.outAmount,
                    type: LightningSuccessType.receive,
                    orderId: boltzOrder.id),
              );
            });
          }
        });
      });
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        logger.d('[Navigation] onWillPop in ReceiveAssetScreen called');
        ref.invalidate(receiveAssetAmountProvider);
        ref.read(sideshiftSendProvider).stopAllStreams();
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
                  right: 30.w,
                  top: 12.h,
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
                if (isLightningOrLiquidAsset) ...[
                  LayerTwoToggleButton(
                    onOptionSelected: (selectedOption) {
                      asset.value = switch (selectedOption) {
                        LayerTwoOption.lightning => _kLightningAsset,
                        LayerTwoOption.lbtc => lbtcAsset,
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
                        UsdtOption.liquid => liquidUsdtAsset,
                        UsdtOption.eth => _kUsdtEthAsset,
                        UsdtOption.trx => _kUsdtTrxAsset,
                      };
                    },
                    initialIndex: asset.value.usdtOption.index,
                  ),
                ],
                if (asset.value.isLightning &&
                    boltzUiState.isLightningView) ...{
                  //ANCHOR - Receive Amount Input
                  ReceiveLightningView(asset: asset.value),
                } else ...{
                  //ANCHOR - Main Address Card
                  addressCards[asset.value.id] ??
                      ReceiveAddressCard(asset: asset.value),
                  SizedBox(height: 40.h),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
