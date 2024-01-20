import 'package:aqua/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

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
