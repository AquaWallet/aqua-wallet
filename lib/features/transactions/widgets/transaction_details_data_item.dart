import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';

class TransactionDetailsDataItem extends StatelessWidget {
  const TransactionDetailsDataItem({
    Key? key,
    required this.uiModel,
  }) : super(key: key);

  final AssetTransactionDetailsDataItemUiModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Text(
            uiModel.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Expanded(
            child: Text(
              uiModel.value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
