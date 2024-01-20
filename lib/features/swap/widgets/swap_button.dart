import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapButton extends HookConsumerWidget {
  const SwapButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(swapButtonEnabledProvider(context));
    final input = ref.watch(sideswapInputStateProvider);

    final onSwap = useCallback(() async {
      if (input.isPeg) {
        ref.read(sideswapWebsocketProvider).sendPeg(isPegIn: input.isPegIn);
      } else {
        final priceOffer = ref.read(sideswapPriceStreamResultStateProvider);
        if (priceOffer != null) {
          ref.read(sideswapWebsocketProvider).sendSwap(priceOffer);
        }
      }
    }, [input]);

    return AquaElevatedButton(
      onPressed: enabled ? onSwap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(.3),
        disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(AppLocalizations.of(context)!.swap),
    );
  }
}
