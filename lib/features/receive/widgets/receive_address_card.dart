import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
      final isLocalAsset = !asset.isLightning && !asset.isSideshift;
      final isLightningWithOrder = asset.isLightning && boltzOrder != null;
      return isLocalAsset || isLightningWithOrder;
    }, [asset, boltzOrder]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        ReceiveAssetAddressQrCard(
          asset: asset,
          address: address,
        ),
        SizedBox(height: 21.h),
        //ANCHOR - Direct Peg-In Button
        if (asset.isLBTC && isDirectPegInEnabled) ...[
          const _DirectPegInButton(),
          SizedBox(height: 21.h),
        ],
        Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          child: Row(
            children: [
              //ANCHOR - Set Amount Button (conditional)
              if (asset.shouldShowAmountInputOnReceive) ...[
                Expanded(
                  child: ReceiveAssetAmountButton(
                    asset: asset,
                  ),
                ),
                SizedBox(width: 20.w),
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
