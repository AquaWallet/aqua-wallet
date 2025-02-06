import 'dart:async';
import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

class MarketplaceTab extends HookConsumerWidget {
  const MarketplaceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));

    if (selectedRegion != null) {
      return const MarketplaceContent();
    }

    final regionAsyncValue = ref.watch(availableRegionsProvider);

    return regionAsyncValue.maybeWhen(
      data: (data) => const MarketplaceRegionSelection(),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      orElse: () => MarketplaceErrorView(
        message: context.loc.regionSettingsScreenError,
      ),
    );
  }
}

class MarketplaceContent extends ConsumerWidget {
  const MarketplaceContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));

    return LayoutBuilder(builder: (context, constraints) {
      double screenWidth = constraints.maxWidth;
      double screenHeight = constraints.maxHeight;
      DeviceCategory deviceCategory = ResponsiveBreakpoints.getDeviceCategory(
        screenWidth,
        screenHeight,
      );

      return Scaffold(
        appBar: AquaAppBar(
          showBackButton: false,
          actionButtonAsset: region?.flagSvg,
          title: context.loc.marketplaceTitle,
          onActionButtonPressed: () =>
              unawaited(ref.read(regionsProvider).setRegionRequired()),
        ),
        body: SafeArea(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: MarketplaceView(
              deviceCategory: deviceCategory,
            ),
          ),
        ),
      );
    });
  }
}

class MarketplaceView extends HookConsumerWidget {
  final DeviceCategory deviceCategory;

  const MarketplaceView({required this.deviceCategory, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketplaceCardsSubtitleText = useMemoized(() {
      return [
        context.loc.marketplaceScreenBuyButtonDescription,
        context.loc.marketplaceScreenExchangeButtonDescription,
        context.loc.marketplaceScreenBtcMapButtonDescription,
        context.loc.marketplaceScreenMyFirstBitcoinButton,
        context.loc.marketplaceScreenBankingButton,
      ];
    });
    final myFirstBitcoinEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.myFirstBitcoinEnabled));
    final isPayWithMoonEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.payWithMoonEnabled));

    // Hide debit card from US customers for now. To be made available in the future when non-reloadable cards are available
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));
    final isMoonAvailableInRegion = region?.iso != 'US';

    // Set the number of marketplace buttons here.  We need this so the card display library can correctly set the flex properties
    var numberOfButtons = 5;
    final conditions = [!isMoonAvailableInRegion, !myFirstBitcoinEnabled];
    for (var condition in conditions) {
      if (condition) {
        numberOfButtons--;
      }
    }

    final hasTransacted = ref.watch(hasTransactedProvider).asData?.value;
    final disableExchanges =
        Platform.isIOS && disableExchagesOnIOS && hasTransacted == false;

    final onDebitCardPressed = useCallback(() {
      //NOTE - Debit card flow is currently only available in dark mode, so we
      // need to force dark mode on screen initialisation and then restore the
      // previous theme state on screen exit.
      final wasAppInDarkMode = ref.read(prefsProvider).isDarkMode;
      ref.read(prefsProvider).setTheme(dark: true);
      //NOTE - Delay the push to allow the theme to be set before the screen is
      // displayed.
      Future.delayed(const Duration(milliseconds: 250), () {
        context.push(DebitCardOnboardingScreen.routeName).then((_) {
          if (!wasAppInDarkMode) {
            ref.read(prefsProvider).setTheme(dark: false);
          }
        });
      });
    }, []);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ANCHOR - Description
          SizedBox(
            height: context.adaptiveDouble(
              smallMobile: 26.0,
              mobile: 60.0,
              tablet: 26.0,
            ),
          ),
          //ANCHOR - Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: LayoutGrid(
              columnSizes: [1.fr, 1.fr],
              rowSizes: List.generate(
                (numberOfButtons / 2)
                    .ceil(), // Calculate rows dynamically based on the number of buttons
                (_) => auto, // Each row adjusts to its content
              ),
              rowGap: 25.0,
              columnGap: 22.0,
              children: [
                //ANCHOR - Buy
                MarketplaceButton(
                  title: context.loc.marketplaceScreenBuyButton,
                  subtitle: marketplaceCardsSubtitleText[0],
                  icon: Svgs.marketplaceBuy,
                  onPressed: disableExchanges
                      ? null
                      : () {
                          context.push(OnRampScreen.routeName);
                        },
                ),
                //ANCHOR - Swaps
                MarketplaceButton(
                  title: context.loc.swaps,
                  subtitle: marketplaceCardsSubtitleText[1],
                  icon: Svgs.marketplaceExchange,
                  onPressed: Platform.isIOS && disableSideswapOnIOS
                      ? null
                      : () {
                          context.push(SwapScreen.routeName);
                        },
                ),
                //ANCHOR - BTC Map
                MarketplaceButton(
                  title: context.loc.marketplaceScreenBtcMapButton,
                  subtitle: marketplaceCardsSubtitleText[2],
                  icon: Svgs.mapIcon,
                  onPressed: () {
                    context.push(
                      WebviewScreen.routeName,
                      extra: WebviewArguments(
                        Uri.parse('https://btcmap.org/map'),
                        context.loc.marketplaceScreenBtcMapButton,
                      ),
                    );
                  },
                ),
                //ANCHOR - My First Bitcoin
                if (myFirstBitcoinEnabled) ...[
                  MarketplaceButton(
                    title: context.loc.marketplaceScreenMyFirstBitcoinButton,
                    subtitle: marketplaceCardsSubtitleText[3],
                    icon: Svgs.website,
                    onPressed: () {
                      context.push(
                        WebviewScreen.routeName,
                        extra: WebviewArguments(
                          Uri.parse('https://myfirstbitcoin.io/bd-2024/'),
                          context.loc.marketplaceScreenMyFirstBitcoinButton,
                        ),
                      );
                    },
                  ),
                ],

                //ANCHOR - Debit Card
                if (isPayWithMoonEnabled && isMoonAvailableInRegion) ...[
                  MarketplaceButton(
                    title: context.loc.marketplaceScreenBankingButton,
                    subtitle: marketplaceCardsSubtitleText[4],
                    icon: Svgs.marketplaceBankings,
                    onPressed: onDebitCardPressed,
                  ),
                ]
              ],
            ),
          ),
          SizedBox(
            height: context.adaptiveDouble(
              smallMobile: 4.0,
              mobile: 20.0,
              tablet: 4.0,
            ),
          ),
        ],
      ),
    );
  }
}
