import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/shared/shared.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebitCardTransactions extends HookConsumerWidget {
  const DebitCardTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmptyView = useState(false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.transactions,
          style: TextStyle(
            fontSize: 16,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
            color: context.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 19),
        if (isEmptyView.value) ...{
          //ANCHOR - Empty View
          GestureDetector(
            onTap: () => isEmptyView.value = false,
            child: const _DebitCardTransactionListEmptyView(),
          ),
        } else ...{
          //ANCHOR - Debit Card Transactions List
          ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              // TODO: Use moonpay transactions
              _DebitCardTransactionListItem(
                onTap: () => isEmptyView.value = true,
                transactionType: _TransactionType.outgoing,
                title: 'Payment in... ?',
                subtitle: 'Recieved',
                amount: 'USD 0.XX',
              ),
              const SizedBox(height: 8),
              _DebitCardTransactionListItem(
                onTap: () => isEmptyView.value = true,
                transactionType: _TransactionType.incoming,
                title: 'Added fund',
                subtitle: 'From Bitcoin',
                amount: 'USD 0.XX',
              ),
            ],
          ),
        },
      ],
    );
  }
}

class _DebitCardTransactionListEmptyView extends StatelessWidget {
  const _DebitCardTransactionListEmptyView();

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      strokeWidth: 1,
      color: AquaColors.dustyGrey,
      padding: EdgeInsets.zero,
      radius: const Radius.circular(9),
      borderType: BorderType.RRect,
      dashPattern: const [2, 3],
      child: Container(
        width: double.infinity,
        height: 80,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AquaColors.charlestonGreen,
          borderRadius: BorderRadius.all(Radius.circular(9)),
        ),
        child: Text(
          context.loc.youHaveNoTransactionsYet,
          style: const TextStyle(
            fontSize: 14,
            height: 1.21,
            color: AquaColors.gray,
            fontFamily: UiFontFamily.inter,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DebitCardTransactionListItem extends HookConsumerWidget {
  const _DebitCardTransactionListItem({
    required this.transactionType,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onTap,
  });

  final _TransactionType transactionType;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return BoxShadowCard(
      color: context.colors.listItemBackground,
      borderRadius: BorderRadius.circular(9),
      bordered: !darkMode,
      borderWidth: 1,
      borderColor: context.colors.cardOutlineColor,
      child: Material(
        color: context.colors.listItemBackground,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Icon
                Skeleton.leaf(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.listItemRoundedIconBackground,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: transactionType.icon.svg(
                      width: 10,
                      height: 10,
                      fit: BoxFit.scaleDown,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.debitCardTransactionTitleColor,
                          fontFamily: UiFontFamily.helveticaNeue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              context.colors.debitCardTransactionSubtitleColor,
                          fontFamily: UiFontFamily.helveticaNeue,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    ],
                  ),
                ),
                //ANCHOR - Amount
                Text(
                  amount,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.debitCardTransactionTitleColor,
                    fontFamily: UiFontFamily.helveticaNeue,
                    fontWeight: FontWeight.w700,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//STUB - Only for mocking
enum _TransactionType {
  incoming,
  outgoing,
}

extension _TransactionTypeExtension on _TransactionType {
  SvgGenImage get icon {
    return this == _TransactionType.incoming
        ? UiAssets.incoming
        : UiAssets.outgoing;
  }
}
