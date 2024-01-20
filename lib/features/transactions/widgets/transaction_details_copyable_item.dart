import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransactionDetailsCopyableItem extends StatelessWidget {
  const TransactionDetailsCopyableItem({
    Key? key,
    required this.uiModel,
  }) : super(key: key);

  final AssetTransactionDetailsCopyableItemUiModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uiModel.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  uiModel.value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: Size.zero),
                onPressed: () => context.copyToClipboard(uiModel.value),
                child: SvgPicture.asset(
                  Svgs.copy,
                  width: 17.w,
                  height: 17.w,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
