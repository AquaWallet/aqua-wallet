import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/debit_card_localizations_extension.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

const _kCardNumber = '4738293805948271';
const _cardCvv = '384';

class DolphinCardScreen extends HookConsumerWidget {
  const DolphinCardScreen({super.key});

  static const routeName = '/dolphinCard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaColors = context.aquaColors;
    final loc = context.loc;

    final reservedMockData = reservedAmountDolphin(context);
    final transactionsMockData = transactionsDolphin(context);

    return ColoredBox(
      color: aquaColors.surfaceBackground,
      child: Row(
        children: [
          SizedBox(
            width: widthOfDolphinLeftSideContent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: aquaColors.surfacePrimary,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AquaDebitCard(
                      style: CardStyle.style1,
                      expiration: DateTime(2016, 7),
                      pan: _kCardNumber,
                      cvv: _cardCvv,
                      text: loc.debitCardLocalizations,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: aquaColors.accentBrandTransparent,
                            ),
                            child: AquaIcon.eyeOpen(
                              color: aquaColors.accentBrand,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AquaText.caption1SemiBold(
                            text: loc.details,
                            color: aquaColors.accentBrand,
                          ),
                        ],
                      ),
                      const SizedBox(width: 64),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: aquaColors.accentBrandTransparent,
                            ),
                            child: AquaIcon.plus(
                              color: aquaColors.accentBrand,
                              padding: const EdgeInsets.all(12),
                              onTap: () => TopUpSideSheet.show(
                                context: context,
                                aquaColors: aquaColors,
                                loc: loc,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AquaText.caption1SemiBold(
                            text: loc.topUp,
                            color: aquaColors.accentBrand,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(
                      height: 0,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: aquaColors.surfacePrimary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 0),
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AquaText.body2SemiBold(
                                text: loc.monthlyLimit,
                                color: aquaColors.textPrimary),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '  \$3,000 ',
                                    style: TextStyle(
                                      color: aquaColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'of \$5,000',
                                    style: TextStyle(
                                      color: aquaColors.textTertiary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          color: aquaColors.accentBrand,
                          backgroundColor: aquaColors.accentBrandTransparent,
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 8,
                          value: 0.7,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                AquaDesktopWalletTile(
                  colors: context.aquaColors,
                  walletName: 'Wallet 1',
                  symbol: '\$',
                  walletBalance: '222,475.48',
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: reservedMockData.isEmpty &&
                          transactionsMockData.isEmpty
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AquaText.body1SemiBold(
                              text: loc.debitCardConfirmedTransactions,
                              color: aquaColors.textPrimary,
                            ),
                            NoDataPlaceholder(
                              title:
                                  loc.marketplaceDolphinCardNoTransactionsYet,
                              subtitle: loc
                                  .marketplaceDolphinCardAddFundsToYourCardAnd,
                              aquaColors: aquaColors,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            if (reservedMockData.isNotEmpty) ...[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AquaText.body1SemiBold(
                                      text: loc.debitCardPendingTransactions,
                                      color: aquaColors.textPrimary,
                                    ),
                                    const SizedBox(height: 16),
                                    Flexible(
                                      child: OutlineContainer(
                                        aquaColors: aquaColors,
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            final item =
                                                reservedMockData[index];
                                            return item;
                                          },
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 0),
                                          itemCount: reservedMockData.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AquaText.body1SemiBold(
                                    text: loc.debitCardConfirmedTransactions,
                                    color: aquaColors.textPrimary,
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: OutlineContainer(
                                      aquaColors: aquaColors,
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          final item =
                                              transactionsMockData[index];
                                          return item;
                                        },
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 0),
                                        itemCount: transactionsMockData.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
