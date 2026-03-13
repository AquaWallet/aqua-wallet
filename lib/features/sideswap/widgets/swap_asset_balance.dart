import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapAssetBalance extends HookConsumerWidget {
  const SwapAssetBalance({
    super.key,
    required this.isReceive,
    this.textColor,
  });

  final bool isReceive;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyle = useMemoized(() {
      return Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colors.onBackground,
          );
    });
    final inputState = ref.watch(sideswapInputStateProvider);
    final asset = isReceive ? inputState.receiveAsset : inputState.deliverAsset;
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));
    final isLoading = ref.watch(swapLoadingIndicatorStateProvider) ==
        const SwapProgressState.connecting();

    if (isLoading) {
      return Text(
        '${context.loc.balance}: 12.34567890 XXX',
        style: textStyle,
      );
    }

    return asset == null
        ? const SizedBox.shrink()
        : Row(
            children: [
              Text(
                '${context.loc.balance}: ',
                style: textStyle,
                textDirection: Directionality.of(context),
              ),
              AssetCryptoAmount(
                forceVisible: true,
                forceDisplayUnit: displayUnit,
                asset: asset,
                amount: asset.amount.toString(),
                style: textStyle!.copyWith(
                  color: textColor ?? Theme.of(context).colors.onBackground,
                ),
              ),
            ],
          );
  }
}
