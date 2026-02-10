import 'package:aqua/features/boltz/providers/boltz_reverse_swap_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveAssetScreen extends HookConsumerWidget {
  const ReceiveAssetScreen({super.key, required this.arguments});

  static const routeName = '/receiveAssetScreen';
  final ReceiveArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = useState(arguments.asset);
    final args = useMemoized(
        () => ReceiveAmountArguments(asset: asset.value), [asset.value]);
    final boltzUiState = ref.watch(boltzReverseSwapProvider);

    final bip21Amount =
        ref.watch(receiveAssetAmountForBip21Provider(asset.value));
    final amount = ref.watch(parsedAssetAmountAsDecimalProvider(bip21Amount));
    final address = ref
        .watch(receiveAssetAddressProvider((asset.value, amount)))
        .valueOrNull;

    final isLightningAmountEntry =
        boltzUiState.isAmountEntry && asset.value.isLightning;

    final title = isLightningAmountEntry
        ? context.loc.boltzInvoiceAmount
        : asset.value.name;

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        logger.debug('[Navigation] onWillPop in ReceiveAssetScreen called');
        ref.invalidate(receiveAssetAddressProvider);
        ref.invalidate(receiveAssetAmountProvider);
      },
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: title,
          colors: context.aquaColors,
          onBackPressed: () {
            if (asset.value.isLightning &&
                (boltzUiState.isQrCode || boltzUiState.isSuccess)) {
              // Reset to enter amount state
              ref.invalidate(boltzReverseSwapProvider);
            } else {
              context.pop();
            }
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Expanded(
                  child: switch (asset.value) {
                    _ when asset.value.isLightning =>
                      ReceiveLightningCard(args: args),
                    _ when asset.value.isAltUsdt => ReceiveSwapContent(
                        deliverAsset: asset.value,
                        swapPair:
                            ReceiveArguments.fromAsset(asset.value).swapPair,
                      ),
                    _ => ReceiveAddressContent(asset: asset.value),
                  },
                ),
                // Bottom navigation for non-Lightning assets or Lightning QR page
                if (!asset.value.isLightning ||
                    !boltzUiState.isAmountEntry) ...[
                  const SizedBox(height: 28),
                  ReceiveAssetBottomNav(
                    asset: asset.value,
                    address: address,
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
