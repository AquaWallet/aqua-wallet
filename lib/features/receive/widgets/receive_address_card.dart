import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveAddressContent extends HookConsumerWidget {
  const ReceiveAddressContent({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bip21Amount = ref.watch(receiveAssetAmountForBip21Provider(asset));
    final amount = ref.watch(parsedAssetAmountAsDecimalProvider(bip21Amount));
    final address =
        ref.watch(receiveAssetAddressProvider((asset, amount))).valueOrNull;
    final isDirectPegInEnabled = ref.watch(prefsProvider).isDirectPegInEnabled;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          //ANCHOR - Address QR Code
          ReceiveAssetAddressQrCard(
            asset: asset,
            address: address ?? '',
          ),
          const SizedBox(height: 24),
          AquaCard.glass(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //ANCHOR - Amount Input Button
                if (asset.shouldShowAmountInputOnReceive) ...[
                  AquaListItem(
                    key: ReceiveAssetKeys.receiveAssetSetAmountButton,
                    onTap: () => context.push(
                      ReceiveAmountScreen.routeName,
                      extra: ReceiveAmountArguments(asset: asset),
                    ),
                    colors: context.aquaColors,
                    title: context.loc.setAmount,
                    iconLeading: AquaIcon.edit(
                      color: context.aquaColors.textSecondary,
                    ),
                    iconTrailing: AquaIcon.chevronForward(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                ],
                if (asset.isLBTC && isDirectPegInEnabled) ...[
                  if (asset.shouldShowAmountInputOnReceive) ...[
                    AquaDivider(colors: context.aquaColors),
                  ],
                  AquaListItem(
                    onTap: () => context.push(DirectPegInScreen.routeName),
                    title: context.loc.directPegIn,
                    colors: context.aquaColors,
                    iconLeading: AquaIcon.pegIn(
                      color: context.aquaColors.textSecondary,
                    ),
                    iconTrailing: AquaIcon.chevronForward(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                ],
                //ANCHOR - Regenerate Address Button
                if (asset.shouldShowRegenerateAddressOnReceive) ...[
                  if (asset.shouldShowAmountInputOnReceive ||
                      (asset.isLBTC && isDirectPegInEnabled)) ...[
                    AquaDivider(colors: context.aquaColors),
                  ],
                  AquaListItem(
                    key: ReceiveAssetKeys.receiveAssetRegenerateAddressButton,
                    onTap: () => ref
                        .read(receiveAssetAddressProvider((asset, amount))
                            .notifier)
                        .forceRefresh(),
                    colors: context.aquaColors,
                    title: context.loc.receiveAssetScreenGenerateNewAddress,
                    iconLeading: AquaIcon.redo(
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
