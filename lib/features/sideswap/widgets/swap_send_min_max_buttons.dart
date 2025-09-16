import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/config/config.dart';

class SwapSendMaxButton extends ConsumerWidget {
  const SwapSendMaxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SwapSendMinMaxButton(
      label: context.loc.swapScreenConvertAllButton,
      onPressed:
          ref.read(sideswapInputStateProvider.notifier).setMaxDeliverAmount,
    );
  }
}

class SwapSendMinButton extends ConsumerWidget {
  const SwapSendMinButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SwapSendMinMaxButton(
      label: context.loc.swapScreenConvertMinButton,
      onPressed:
          ref.read(sideswapInputStateProvider.notifier).setMinDeliverAmount,
    );
  }
}

class _SwapSendMinMaxButton extends HookConsumerWidget {
  const _SwapSendMinMaxButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        textStyle: Theme.of(context).textTheme.titleSmall,
        foregroundColor: Theme.of(context).colors.onBackground,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
      ),
      child: Text(label),
    );
  }
}
