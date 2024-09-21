import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class ReceiveSideshiftOrderExpireLabel extends HookConsumerWidget {
  const ReceiveSideshiftOrderExpireLabel({
    super.key,
    required this.order,
  });

  final SideshiftOrder? order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedExpiresDate = order?.expiresAt != null
        ? DateFormat('MMMM d, y').format(order!.expiresAt!)
        : '---';

    //ANCHOR - Expiry
    return Text(
      context.loc.receiveAssetScreenExpiresOn(formattedExpiresDate),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onBackground,
          ),
    );
  }
}
