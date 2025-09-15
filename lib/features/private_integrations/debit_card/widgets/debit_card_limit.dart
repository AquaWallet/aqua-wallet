import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebitCardLimit extends HookConsumerWidget {
  const DebitCardLimit({
    super.key,
    required this.availableAmount,
    required this.usedAmount,
  });

  final double availableAmount;
  final double usedAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatAmount = useCallback((double value) {
      if (value == 0) {
        return '0';
      }
      final amount =
          ref.read(fiatProvider).formattedFiat(DecimalExt.fromDouble(value));
      return value % 1 == 0 ? amount.split('.').first : amount;
    });
    final availableAmountFormatted = useMemoized(
      () => formatAmount(availableAmount),
    );
    final usedAmountFormatted = useMemoized(
      () => formatAmount(usedAmount),
    );
    final progress = useMemoized(
      () => availableAmount <= 0 ? 0.0 : usedAmount / availableAmount,
    );

    return Column(
      children: [
        Row(
          children: [
            //ANCHOR - Limit Amount Label
            Text(
              context.loc.monthlyLimit,
              style: TextStyle(
                fontSize: 16,
                fontFamily: UiFontFamily.inter,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            const Spacer(),
            Skeleton.unite(
              child: Row(
                children: [
                  //ANCHOR - Used Amount Label
                  Text(
                    '\$$usedAmountFormatted',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: UiFontFamily.inter,
                      fontWeight: FontWeight.w500,
                      color: context.colors.debitCardUsedAmountLabelColor,
                    ),
                  ),
                  //ANCHOR - Available Amount Label
                  Text(
                    ' / \$$availableAmountFormatted',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: UiFontFamily.inter,
                      fontWeight: FontWeight.w500,
                      color: context.colors.debitCardAvailableAmountLabelColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        //ANCHOR - Limit Indicator
        Skeleton.leaf(
          child: LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(4),
            color: Color.lerp(
              AquaColors.debitCardProgressGradientStartColor,
              AquaColors.debitCardProgressGradientEndColor,
              progress,
            ),
          ),
        ),
      ],
    );
  }
}
