import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swap/swap.dart';

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
