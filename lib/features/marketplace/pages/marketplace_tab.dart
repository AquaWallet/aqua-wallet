import 'dart:async';
import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/pages/swap_screen.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
          title: context.loc.homeTabMarketplaceTitle,
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
        context.loc.marketplaceScreenMyFirstBitcoinButtonDescription,
        context.loc.marketplaceScreenBankingButton,
      ];
    });
    final myFirstBitcoinEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.myFirstBitcoinEnabled));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ANCHOR - Description
          SizedBox(
            height: context.adaptiveDouble(
              smallMobile: 26.h,
              mobile: 60.h,
              tablet: 26.h,
            ),
          ),
          //ANCHOR - Buttons
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 22.w,
            mainAxisSpacing: 25.h,
            childAspectRatio: context.adaptiveDouble(
              smallMobile: 175 / 216,
              mobile: 165 / 216,
              tablet: 190 / 216,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            children: [
              //ANCHOR - Buy
              MarketplaceButton(
                title: context.loc.marketplaceScreenBuyButton,
                subtitle: marketplaceCardsSubtitleText[0],
                icon: Svgs.marketplaceBuy,
                onPressed: Platform.isIOS &&
                        disableExchagesOnIOS &&
                        ref.watch(regionsProvider).currentRegion?.iso ==
                            RegionsStatic.us.iso
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(OnRampScreen.routeName);
                      },
              ),
              //ANCHOR - Swaps
              MarketplaceButton(
                title: context.loc.marketplaceScreenExchangeButton,
                subtitle: marketplaceCardsSubtitleText[1],
                icon: Svgs.marketplaceExchange,
                onPressed: Platform.isIOS && disableSideswapOnIOS
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(SwapScreen.routeName);
                      },
              ),
              //ANCHOR - BTC Map
              MarketplaceButton(
                title: context.loc.marketplaceScreenBtcMapButton,
                subtitle: marketplaceCardsSubtitleText[2],
                icon: Svgs.mapIcon,
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    WebviewScreen.routeName,
                    arguments: WebviewArguments(
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
                    Navigator.of(context).pushNamed(
                      WebviewScreen.routeName,
                      arguments: WebviewArguments(
                        Uri.parse('https://myfirstbitcoin.io/bd-2024/'),
                        context.loc.marketplaceScreenMyFirstBitcoinButton,
                      ),
                    );
                  },
                ),
              ],

              //ANCHOR - Debit Card
              MarketplaceButton(
                title: context.loc.marketplaceScreenBankingButton,
                subtitle: marketplaceCardsSubtitleText[4],
                icon: Svgs.marketplaceBankings,
              ),
            ],
          ),
          SizedBox(
            height: context.adaptiveDouble(
              smallMobile: 4.h,
              mobile: 20.h,
              tablet: 4.h,
            ),
          ),
        ],
      ),
    );
  }
}
