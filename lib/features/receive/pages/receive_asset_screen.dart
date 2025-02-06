import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/theme/app_styles.dart';
import 'package:aqua/features/boltz/providers/boltz_reverse_swap_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAssetScreen extends HookConsumerWidget {
  const ReceiveAssetScreen({super.key, required this.arguments});

  static const routeName = '/receiveAssetScreen';
  final ReceiveArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = useState(arguments.asset);
    final lbtcAsset = ref.read(manageAssetsProvider).lbtcAsset;
    final boltzUiState = ref.watch(boltzReverseSwapProvider);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        logger.debug('[Navigation] onWillPop in ReceiveAssetScreen called');
        ref.invalidate(receiveAssetAddressProvider);
        ref.invalidate(receiveAssetAmountProvider);
      },
      child: Scaffold(
        appBar: AquaAppBar(
          title: context.loc.receive,
          iconBackgroundColor:
              Theme.of(context).colors.addressFieldContainerBackgroundColor,
          showActionButton: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 14.0, bottom: 32.0),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (asset.value.isLayerTwo)
                        LayerTwoToggleButton(
                          onOptionSelected: (selectedOption) {
                            asset.value =
                                selectedOption == LayerTwoOption.lightning
                                    ? Asset.lightning()
                                    : lbtcAsset;
                          },
                          initialIndex: asset.value.isLightning
                              ? LayerTwoOption.lightning.index
                              : LayerTwoOption.lbtc.index,
                        ),
                      asset.value.isLightning
                          ? ReceiveLightningCard(asset: asset.value)
                          : asset.value.isAltUsdt
                              ? ReceiveSwapCard(
                                  deliverAsset: asset.value,
                                  swapPair:
                                      ReceiveArguments.fromAsset(asset.value)
                                          .swapPair)
                              : ReceiveAddressCard(asset: asset.value)
                    ],
                  ),
                ),
              ),
              if (boltzUiState.isAmountEntry) _BottomButton(asset: asset.value),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomButton extends ConsumerWidget {
  const _BottomButton({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!asset.isLightning) return const SizedBox.shrink();

    final amountForBip21 = ref.watch(receiveAssetAmountForBip21Provider(asset));
    final amountAsDecimal =
        ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: SizedBox(
        width: double.infinity,
        height: 50.0,
        child: AquaElevatedButton(
          onPressed: () => ref
              .read(boltzReverseSwapProvider.notifier)
              .generateInvoice(amountAsDecimal, context.loc),
          child: Text(context.loc.boltzGenerateInvoice),
        ),
      ),
    );
  }
}
