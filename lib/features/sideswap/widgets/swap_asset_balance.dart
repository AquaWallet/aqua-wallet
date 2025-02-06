import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/config/config.dart';

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
    final balance = isReceive
        ? inputState.receiveAssetBalance
        : inputState.deliverAssetBalance;
    final asset = isReceive ? inputState.receiveAsset : inputState.deliverAsset;
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));
    final cryptoAmountInSats = useMemoized(() {
      return balance != ''
          ? ref.read(formatterProvider).parseAssetAmountDirect(
                amount: balance,
                precision: asset?.precision ?? 8,
              )
          : 0;
    }, [balance]);
    final isLoading = ref.watch(swapLoadingIndicatorStateProvider) ==
        const SwapProgressState.connecting();

    if (isLoading) {
      return Text(
        '${context.loc.balance}: 12.34567890 XXX',
        style: textStyle,
      );
    }

    return balance.isEmpty || asset == null
        ? const SizedBox.shrink()
        : Row(
            children: [
              Text(
                '${context.loc.balance}: ',
                style: textStyle,
              ),
              AssetCryptoAmount(
                forceVisible: true,
                forceDisplayUnit: displayUnit,
                asset: asset,
                amount: cryptoAmountInSats.toString(),
                style: textStyle!.copyWith(
                  color: textColor ?? Theme.of(context).colors.onBackground,
                ),
              ),
            ],
          );
  }
}
