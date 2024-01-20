import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletHeaderBtcPrice extends StatelessWidget {
  const WalletHeaderBtcPrice(this.uiModel, {super.key});

  final BtcPriceUiModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          //ANCHOR - Title
          child: Text(
            AppLocalizations.of(context)!.walletBitcoinPriceTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Row(
            children: [
              //ANCHOR - Price
              Text(
                "\$${uiModel.price}",
                style: GoogleFonts.arimo(
                  fontWeight: FontWeight.w700,
                  fontSize: 32.sp,
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
        ),
      ],
    );
  }
}
