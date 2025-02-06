import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:aqua/config/config.dart';

class ReceiveSwapOrderExpireLabel extends HookConsumerWidget {
  const ReceiveSwapOrderExpireLabel({
    super.key,
    required this.order,
  });

  final SwapOrder? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order?.expiresAt == null) {
      return const SizedBox.shrink();
    }

    final formattedExpiresDate =
        DateFormat('MMMM d, y').format(order!.expiresAt!);

    //ANCHOR - Expiry
    return Text(
      context.loc.receiveAssetScreenExpiresOn(formattedExpiresDate),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colors.onBackground,
          ),
    );
  }
}
