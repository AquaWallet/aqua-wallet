import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swap/swap.dart';

class PegOrderDetails extends HookConsumerWidget {
  const PegOrderDetails({
    super.key,
    required this.data,
    required this.input,
  });

  final SwapPegReviewModel data;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        PegReviewInfoCard(
          data: data,
          input: input,
        ),
        const Spacer(),
        SwapSlider(
          onConfirm: () => ref.read(pegProvider.notifier).executeTransaction(),
        ),
        SizedBox(height: kBottomPadding),
      ],
    );
  }
}
