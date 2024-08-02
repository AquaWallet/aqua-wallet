import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletTabHeader extends HookConsumerWidget {
  const WalletTabHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final btcPrice = ref.watch(btcPriceProvider(2));
    final verticalPadding = useMemoized(() => context.adaptiveDouble(
          mobile: 24.h,
          smallMobile: 28.h,
        ));
    final horizontalPadding = useMemoized(() => context.adaptiveDouble(
          mobile: 28.w,
          smallMobile: 32.w,
        ));

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Container(
        height: 265.h,
        decoration: AppStyle.getHeaderDecoration(
          color: Theme.of(context).colors.headerBackgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.only(
                  top: verticalPadding * 2.5,
                  bottom: verticalPadding,
                  left: horizontalPadding,
                  right: horizontalPadding,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        //ANCHOR - Logo
                        SvgPicture.asset(
                          darkMode ? Svgs.aquaLogoWhite : Svgs.aquaLogoColor,
                          colorFilter: botevMode
                              ? ColorFilter.mode(
                                  Theme.of(context).colorScheme.background,
                                  BlendMode.srcIn,
                                )
                              : null,
                          width: context.adaptiveDouble(
                            smallMobile: 100.w,
                            mobile: 130.w,
                            wideMobile: 75.w,
                            tablet: 100.w,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    //ANCHOR - Bitcoin Price
                    btcPrice.map(
                      data: (e) => e.maybeMap(
                        data: (e) => WalletHeaderBtcPrice(e.value),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      error: (e) => const SizedBox.shrink(),
                      loading: (_) => Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //ANCHOR - Send, Receive and Scan buttons
            const WalletExchangeButtonsPanel()
          ],
        ),
      ),
    );
  }
}
