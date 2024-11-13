import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
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
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          );
    });
    final inputState = ref.watch(sideswapInputStateProvider);
    final balance = isReceive
        ? inputState.receiveAssetBalance
        : inputState.deliverAssetBalance;
    final asset = isReceive ? inputState.receiveAsset : inputState.deliverAsset;
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
                context.loc.balance + ': ',
                style: textStyle,
              ),
              Text(
                '$balance ${asset.ticker}',
                style: textStyle!.copyWith(
                  color:
                      textColor ?? Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          );
  }
}
