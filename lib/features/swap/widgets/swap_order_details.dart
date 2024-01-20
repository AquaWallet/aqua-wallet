import 'package:aqua/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapOrderDetails extends HookConsumerWidget {
  const SwapOrderDetails({
    super.key,
    required this.order,
    required this.input,
  });

  final SwapStartWebResult order;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SwapReviewInfoCard(
          order: order,
          input: input,
        ),
        const Spacer(),
        SwapSlider(
          onConfirm: () => ref.read(swapProvider.notifier).executeTransaction(),
        ),
        SizedBox(height: kBottomPadding),
      ],
    );
  }
}
