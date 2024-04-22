import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/marketplace/meld_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnRampScreen extends ConsumerWidget {
  const OnRampScreen({super.key});
  static const routeName = '/selectBuyAndSellPlatform';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: '',
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 560.h,
                width: 320.w,
                padding: EdgeInsets.all(26.h),
                child: Column(
                  children: [
                    Text(
                      context.loc.buyWithFiatScreenTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 30.sp),
                    ),
                    SizedBox(
                      height: 40.h,
                    ),
                    BuyAndSellPlatformButton(
                      svgImage: Svgs.meldLogo,
                      onPressed: () async {
                        final address =
                            await ref.read(bitcoinProvider).getReceiveAddress();
                        final uri = ref.read(meldUriProvider(address?.address));
                        if (context.mounted) {
                          Navigator.of(context).pushNamed(
                              WebviewScreen.routeName,
                              arguments: WebviewArguments(
                                  uri, context.loc.buyWithFiatScreenTitle));
                        }
                      },
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    const BuyAndSellPlatformButton(
                      svgImage: Svgs.beaverLogo,
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    const BuyAndSellPlatformButton(
                      svgImage: Svgs.pocketBitcoinLogo,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 220.h,
          ),
        ],
      ),
    );
  }
}

class BuyAndSellPlatformButton extends StatelessWidget {
  final String svgImage;
  final VoidCallback? onPressed;
  const BuyAndSellPlatformButton({
    super.key,
    required this.svgImage,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: 125.h,
        width: 250.w,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 24.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: Theme.of(context).colorScheme.onInverseSurface,
        ),
        child: Opacity(
          opacity: onPressed == null ? 0.2 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.asset(
                svgImage,
                height: svgImage == Svgs.beaverLogo ? 22.h : 48.h,
                colorFilter: svgImage == Svgs.pocketBitcoinLogo
                    ? ColorFilter.mode(
                        Theme.of(context).colors.altScreenBackground,
                        BlendMode.saturation)
                    : null,
                fit: BoxFit.scaleDown,
              ),
              if (svgImage == Svgs.pocketBitcoinLogo)
                SizedBox(
                  height: 10.h,
                ),
              if (svgImage != Svgs.meldLogo)
                Text(
                  context.loc.marketplaceBuySellScreenPlatformButtonSubText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
