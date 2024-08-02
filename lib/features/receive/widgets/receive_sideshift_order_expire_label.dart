import 'package:aqua/data/provider/sideshift/sideshift.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:intl/intl.dart';

class ReceiveSideshiftOrderExpireLabel extends HookConsumerWidget {
  const ReceiveSideshiftOrderExpireLabel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sideshiftOrder = ref.watch(sideshiftPendingOrderProvider);

    final formattedExpiresDate = sideshiftOrder?.expiresAt != null
        ? DateFormat('MMMM d, y').format(sideshiftOrder!.expiresAt!)
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
