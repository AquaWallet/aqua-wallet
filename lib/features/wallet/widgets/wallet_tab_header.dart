import 'package:aqua/common/common.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/wallet_header_display_provider.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    final aquaLogoSize = useMemoized(() {
      return context.adaptiveDouble(
        smallMobile: 130.0,
        mobile: 161.0,
        wideMobile: 105.0,
        tablet: 130.0,
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
      height: context.adaptiveDouble(mobile: 262.0, smallMobile: 224.0),
      decoration: BoxDecoration(
        color: context.colors.headerBackgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(9.0),
          bottomRight: Radius.circular(9.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(4, 0),
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
              child: GestureDetector(
                onTap: () =>
                    ref.read(walletHeaderDisplayProvider.notifier).toggle(),
                child: Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 29.0,
                    vertical: context.adaptiveDouble(
                      smallMobile: 10.0,
                      mobile: 14.0,
                      tablet: 20.0,
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
                              width: 40.0,
                              height: 40.0,
                              colorFilter: ColorFilter.mode(
                                context.colors.notificationButtonBackground,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                        ],
                      ),
                      //ANCHOR - Total Balance / BTC Price
                      const Expanded(
                        child: _BalancePriceContent(),
                      ),
                    ],
                  ),
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

class _BalancePriceContent extends HookConsumerWidget {
  const _BalancePriceContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayMode = ref.watch(walletHeaderDisplayProvider);

    return Container(
      width: double.infinity,
      alignment: Alignment.bottomLeft,
      child: switch (displayMode) {
        AsyncData(:final value) => switch (value) {
            WalletHeaderDisplay.btcPrice => const WalletHeaderBtcPrice(),
            _ => const _TotalBalance(),
          },
        _ => const _TotalBalance(),
      },
    );
  }
}

class _TotalBalance extends HookConsumerWidget {
  const _TotalBalance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unifiedBalance = ref.watch(unifiedBalanceProvider);
    final currentRate =
        ref.watch(exchangeRatesProvider.select((p) => p.currentCurrency));

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Total balance title
        Row(
          children: [
            Text(
              context.loc.walletTotalBalanceTitle,
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
            const SizedBox(width: 8),
            const BalanceVisibilityToggle(),
          ],
        ),
        const SizedBox(height: 4),
        //ANCHOR - Total balance
        Skeletonizer(
          enabled: unifiedBalance == null,
          child: HeaderAmount(
            amount:
                "${currentRate.currency.symbol}${unifiedBalance?.formatted}",
          ),
        ),
      ],
    );
  }
}
