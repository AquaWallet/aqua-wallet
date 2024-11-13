import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

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
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.r,
          ),
        ),
      ),
      child: Text(label),
    );
  }
}
