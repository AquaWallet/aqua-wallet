import 'dart:async';
import 'dart:io';

import 'package:aqua/common/utils/encode_query_component.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/marketplace/meld_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/pages/swap_screen.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketplaceTab extends HookConsumerWidget {
  const MarketplaceTab({Key? key}) : super(key: key);

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
        context.loc.marketplaceScreenRemittanceButtonDescription,
        context.loc.marketplaceScreenBankingButton,
      ];
    });

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
                onPressed: Platform.isIOS && disableExchagesOnIOS
                    ? null
                    : () async {
                        if (multipleOnramps) {
                          Navigator.of(context)
                              .pushNamed(OnRampScreen.routeName);
                        } else {
                          final address = await ref
                              .read(bitcoinProvider)
                              .getReceiveAddress();
                          final uri =
                              ref.read(meldUriProvider(address?.address));
                          if (context.mounted) {
                            Navigator.of(context).pushNamed(
                              WebviewScreen.routeName,
                              arguments: WebviewArguments(
                                uri,
                                context.loc.buyWithFiatScreenTitle,
                              ),
                            );
                          }
                        }
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
              //ANCHOR - Bills
              MarketplaceButton(
                title: context.loc.marketplaceScreenRemittanceButton,
                subtitle: marketplaceCardsSubtitleText[2],
                icon: Svgs.marketplaceRemittance,
              ),
              //ANCHOR - Debit Card
              MarketplaceButton(
                title: context.loc.marketplaceScreenBankingButton,
                subtitle: marketplaceCardsSubtitleText[3],
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
          //ANCHOR - Contact Button
          const _MarketplaceContactButton(),
        ],
      ),
    );
  }
}

class _MarketplaceContactButton extends StatelessWidget {
  const _MarketplaceContactButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Theme.of(context).colorScheme.surface,
      ),
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 18.h),
      child: Center(
        child: RichText(
          text: TextSpan(
            text: context.loc.marketplaceScreenBottomBoxText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14.sp,
                ),
            children: [
              WidgetSpan(
                child: SizedBox(width: 6.w),
              ),
              TextSpan(
                text: context.loc.marketplaceScreenBottomBoxTextBoldText,
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    await launchUrl(Uri(
                      scheme: 'mailto',
                      path: aquaSupportEmail,
                      query: encodeQueryParameters({
                        'subject': 'AQUA Marketplace Request',
                      }),
                    ));
                  },
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
