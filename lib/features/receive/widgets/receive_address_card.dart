import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/receive/keys/receive_screen_keys.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/config/config.dart';

class ReceiveAddressCard extends HookConsumerWidget {
  const ReceiveAddressCard({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDirectPegInEnabled =
        ref.watch(prefsProvider.select((p) => p.isDirectPegInEnabled));
    final amountForBip21 = ref.watch(receiveAssetAmountForBip21Provider(asset));
    final amountAsDecimal =
        ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));
    final address = ref
            .watch(receiveAssetAddressProvider((asset, amountAsDecimal)))
            .asData
            ?.value ??
        '';

    final boltzOrder =
        ref.watch(boltzReverseSwapProvider).whenOrNull(qrCode: (s) => s);
    final enableShareButton = useMemoized(() {
      final isLocalAsset = !asset.isLightning && !asset.isAltUsdt;
      final isLightningWithOrder = asset.isLightning && boltzOrder != null;
      return isLocalAsset || isLightningWithOrder;
    }, [asset, boltzOrder]);

    final showAmountBottomSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ReceiveAmountInputSheet(
            asset: asset,
            onConfirm: (amount) {
              ref.read(receiveAssetAmountProvider.notifier).state = amount;
              context.pop();
            },
            onCancel: () => context.pop(),
            onChanged: (_) => null,
          ),
        ),
      );
    }, [asset]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24.0),
        ReceiveAssetAddressQrCard(
            asset: asset,
            address: address,
            onRegenerate: asset.isBTC || asset.isLiquid
                ? () => ref
                    .read(receiveAssetAddressProvider((asset, amountAsDecimal))
                        .notifier)
                    .forceRefresh()
                : null),
        const SizedBox(height: 21.0),
        //ANCHOR - Direct Peg-In Button
        if (asset.isLBTC && isDirectPegInEnabled) ...[
          const _DirectPegInButton(),
          const SizedBox(height: 21.0),
        ],
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Row(
            children: [
              //ANCHOR - Set Amount Button (conditional)
              if (asset.shouldShowAmountInputOnReceive) ...[
                Expanded(
                  child: _ReceiveSetAmountButton(
                    onPressed: showAmountBottomSheet,
                  ),
                ),
                const SizedBox(width: 20.0),
              ],
              //ANCHOR - Share Button
              Flexible(
                flex: asset.shouldShowAmountInputOnReceive ? 0 : 1,
                child: ReceiveAssetAddressShareButton(
                  isEnabled: enableShareButton,
                  isExpanded: !asset.shouldShowAmountInputOnReceive,
                  address: address,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DirectPegInButton extends StatelessWidget {
  const _DirectPegInButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      child: OutlinedButton(
        onPressed: () => context.push(DirectPegInScreen.routeName),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colors.onBackground,
          fixedSize: const Size(double.maxFinite, 38.0),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: BorderSide(
            width: 2.0,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Text(context.loc.directPegIn),
      ),
    );
  }
}

class _ReceiveSetAmountButton extends StatelessWidget {
  const _ReceiveSetAmountButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: ReceiveAssetKeys.receiveAssetSetAmountButton,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colors.onBackground,
        fixedSize: const Size(double.maxFinite, 38.0),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        side: BorderSide(
          width: 2.0,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      child: Text(context.loc.setAmount),
    );
  }
}
