import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HeaderAmount extends ConsumerWidget {
  const HeaderAmount({super.key, required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceHidden =
        ref.watch(prefsProvider.select((p) => p.isBalanceHidden));
    return Text(
      isBalanceHidden ? hiddenBalancePlaceholder : amount,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: context.colorScheme.onPrimaryContainer,
        fontSize: context.adaptiveDouble(
          smallMobile: 28.0,
          mobile: 30.0,
          wideMobile: 18.0,
          tablet: 30.0,
        ),
      ),
    );
  }
}

class WalletHeaderBtcPrice extends ConsumerWidget {
  const WalletHeaderBtcPrice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btcPriceAsync = ref.watch(btcPriceProvider(2));
    final uiModel =
        btcPriceAsync.valueOrNull?.valueOrNull ?? BtcPriceUiModel.placeholder;
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Title
        Text(
          context.loc.walletBitcoinPriceTitle,
          style: TextStyle(
            letterSpacing: -0.1,
            fontWeight: FontWeight.w700,
            color: context.colors.walletAmountLabel,
            fontSize: context.adaptiveDouble(
              mobile: 14.0,
              smallMobile: 12.0,
              wideMobile: 10.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Skeletonizer(
          enabled: btcPriceAsync.isLoading ||
              (btcPriceAsync.value?.isLoading ?? false) ||
              btcPriceAsync.valueOrNull == null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              //ANCHOR - Price
              Text(
                "${currentRate.currency.symbol}${uiModel.price}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onPrimaryContainer,
                  fontSize: context.adaptiveDouble(
                    smallMobile: 28.0,
                    mobile: 30.0,
                    wideMobile: 18.0,
                    tablet: 30.0,
                  ),
                ),
              ),
              if (uiModel.priceChange != '') ...[
                const SizedBox(width: 10.0),
                // ANCHOR - Price change
                Text(
                  '${uiModel.priceChange} ${uiModel.priceChangePercent}',
                  style: TextStyle(
                    height: 1.5,
                    fontSize: 14.0,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w700,
                    color: uiModel.priceChange.isEmpty
                        ? context.colors.neutraBTCDeltaColor
                        : int.parse(uiModel.priceChange).isNegative
                            ? context.colors.redBTCDeltaColor
                            : context.colors.greenBTCDeltaColor,
                  ),
                ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}
