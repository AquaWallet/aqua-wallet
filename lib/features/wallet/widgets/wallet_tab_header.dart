import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletTabHeader extends HookConsumerWidget {
  const WalletTabHeader({
    super.key,
    this.showNotification = false,
  });

  final bool showNotification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final btcPrice = ref.watch(btcPriceProvider(2));
    final aquaLogoSize = useMemoized(() {
      return context.adaptiveDouble(
        smallMobile: 130.w,
        mobile: 161.w,
        wideMobile: 105.w,
        tablet: 130.w,
      );
    }, [context.mounted]);

    final logo = useMemoized(() {
      if (botevMode) {
        return UiAssets.svgs.light.aquaLogo;
      }
      return darkMode
          ? UiAssets.svgs.dark.aquaLogo
          : UiAssets.svgs.light.aquaLogo;
    }, [darkMode, botevMode]);

    return Container(
      height: 262.h,
      decoration: BoxDecoration(
        color: context.colors.headerBackgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(9.r),
          bottomRight: Radius.circular(9.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(4, 4),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 29.w,
                  vertical: context.adaptiveDouble(
                    smallMobile: 10.h,
                    mobile: 7.h,
                    tablet: 20.h,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        //ANCHOR - Logo
                        logo.svg(width: aquaLogoSize),
                        const Spacer(),
                        //ANCHOR - Notification Button
                        Opacity(
                          opacity: showNotification ? 1 : 0,
                          child: UiAssets.svgs.walletHeaderNotification.svg(
                            width: 40.r,
                            height: 40.r,
                            colorFilter: ColorFilter.mode(
                              context.colors.notificationButtonBackground,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      ],
                    ),
                    //ANCHOR - Bitcoin Price
                    Expanded(
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        child: btcPrice.map(
                          data: (e) => e.maybeMap(
                            data: (e) => WalletHeaderBtcPrice(e.value),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          error: (e) => const SizedBox.shrink(),
                          loading: (_) => Center(
                            child: CircularProgressIndicator(
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          //ANCHOR - Send, Receive and Scan buttons
          const WalletExchangeButtonsPanel()
        ],
      ),
    );
  }
}
