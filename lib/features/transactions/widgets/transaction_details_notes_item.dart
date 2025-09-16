import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/transactions/transactions.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/config/config.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          children: [
            Text(
              context.loc.myNotes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Icon(
                Icons.edit_outlined,
                size: 12.0,
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
                            color: Theme.of(context).colors.onBackground,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
