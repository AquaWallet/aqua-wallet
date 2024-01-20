import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapAssetBalance extends HookConsumerWidget {
  const SwapAssetBalance({super.key, required this.isReceive});

  final bool isReceive;

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
        AppLocalizations.of(context)!.exchangeSwapBalance('12.34567890', 'XXX'),
        style: textStyle,
      );
    }

    return balance.isEmpty || asset == null
        ? const SizedBox.shrink()
        : Text(
            AppLocalizations.of(context)!
                .exchangeSwapBalance(balance, asset.ticker),
            style: textStyle,
          );
  }
}
