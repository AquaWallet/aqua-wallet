import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletHeaderBtcPrice extends ConsumerWidget {
  const WalletHeaderBtcPrice(this.uiModel, {super.key});

  final BtcPriceUiModel uiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.walletBitcoinPriceTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: context.adaptiveDouble(
                  smallMobile: 12.sp,
                  mobile: 14.sp,
                  wideMobile: 10.sp,
                ),
              ),
        ),
        Row(
          children: [
            //ANCHOR - Price
            Text(
              "${currentRate.currency.symbol}${uiModel.price}",
              style: GoogleFonts.arimo(
                fontWeight: FontWeight.w700,
                fontSize: context.adaptiveDouble(
                  smallMobile: 28.sp,
                  mobile: 33.sp,
                  wideMobile: 18.sp,
                  tablet: 30.sp,
                ),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: 8.w),
            //ANCHOR - Price change
            Text(
              '${uiModel.priceChange} ${uiModel.priceChangePercent}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: uiModel.priceChange.isEmpty
                        ? null
                        : int.parse(uiModel.priceChange).isNegative
                            ? Theme.of(context).colors.redBTCDeltaColor
                            : Theme.of(context).colors.greenBTCDeltaColor,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
