import 'package:coin_cz/features/internal_send/internal_send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class InternalSendReviewOrderIdCard extends HookConsumerWidget {
  const InternalSendReviewOrderIdCard({
    super.key,
    required this.arguments,
  });

  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    return BoxShadowCard(
      color: context.colors.addressFieldContainerBackgroundColor,
      bordered: !darkMode,
      borderRadius: BorderRadius.circular(12.0),
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        //ANCHOR - Order ID
        child: LabelCopyableTextView(
          label: context.loc.sideswapOrderID,
          value: arguments.maybeWhen(
            swapReview: (_, __, swap) => swap.result?.orderId ?? '',
            pegReview: (_, __, swap) => swap.order.orderId,
            orElse: () => '',
          ),
        ),
      ),
    );
  }
}
