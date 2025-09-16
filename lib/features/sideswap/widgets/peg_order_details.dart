import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/transactions/transactions.dart';

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
        const SizedBox(height: 12.0),
        const TransactionFeeBreakdownCard(
          args: FeeStructureArguments.sideswap(),
        ),
        const SizedBox(height: 20.0),
        SwapSlider(
          onConfirm: () => ref.read(pegProvider.notifier).executeTransaction(),
        ),
        const SizedBox(height: kBottomPadding),
      ],
    );
  }
}
