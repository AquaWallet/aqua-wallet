import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SideswapPegDetailsCard extends HookConsumerWidget {
  const SideswapPegDetailsCard({
    super.key,
    required this.uiModel,
  });

  final AssetTransactionDetailsUiModel uiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;

    final TransactionDbModel? dbTransaction =
        useMemoized(() => arguments.dbTransaction);

    if (dbTransaction == null || !dbTransaction.isPeg) {
      return const SizedBox.shrink();
    }

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      bordered: true,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Title
            Text(
              dbTransaction.isPegIn
                  ? context.loc.sideswapPegInDescription
                  : context.loc.sideswapPegOutDescription,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 24.h),
            //ANCHOR - Transaction Id
            LabelCopyableTextView(
              label: context.loc.pegOrderReviewOrderId,
              value: dbTransaction.serviceOrderId ?? '-',
            ),
            SizedBox(height: 18.h),
            //ANCHOR - Deposit Address
            LabelCopyableTextView(
              label: context.loc.sideshiftDepositAddress,
              value: dbTransaction.serviceAddress ?? '-',
            ),
          ],
        ),
      ),
    );
  }
}
