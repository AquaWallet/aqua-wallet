import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';

class TransactionDetailsNotesItem extends StatelessWidget {
  const TransactionDetailsNotesItem({
    super.key,
    required this.uiModel,
  });

  final AssetTransactionDetailsUiModel uiModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        child: Row(
          children: [
            Text(
              context.loc.assetTransactionDetailsMyNotes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Icon(
                Icons.edit_outlined,
                size: 12.w,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: uiModel.notes?.isNotEmpty == true
                  ? Text(
                      uiModel.notes!,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  : Text(
                      context.loc.assetTransactionDetailsMyNotesPlaceholder,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
