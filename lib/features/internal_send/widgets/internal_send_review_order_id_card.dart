import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class InternalSendReviewOrderIdCard extends HookConsumerWidget {
  const InternalSendReviewOrderIdCard({
    super.key,
    required this.arguments,
  });

  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    return BoxShadowCard(
      color: context.colors.addressFieldContainerBackgroundColor,
      bordered: !darkMode,
      borderRadius: BorderRadius.circular(12.r),
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        //ANCHOR - Order ID
        child: LabelCopyableTextView(
          label: context.loc.internalSendReviewOrderId,
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
