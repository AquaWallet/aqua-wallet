import 'dart:async';

import 'package:aqua/common/utils/encode_query_component.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/marketplace/meld_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/pages/swap_screen.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:flutter/gestures.dart';
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
        message: AppLocalizations.of(context)!.regionSettingsScreenError,
      ),
    );
  }
}

class MarketplaceContent extends ConsumerWidget {
  const MarketplaceContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionsProvider.select((p) => p.currentRegion));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        actionButtonAsset: region?.iso,
        title: AppLocalizations.of(context)!.homeTabMarketplaceTitle,
        onActionButtonPressed: () =>
            unawaited(ref.read(regionsProvider).setRegionRequired()),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Description
            SizedBox(height: 28.h),
            Padding(
              padding: EdgeInsets.only(left: 30.w),
              child: Text.rich(
                TextSpan(
                  text: AppLocalizations.of(context)!
                      .marketplaceScreenDescriptionNormal,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                  children: [
                    TextSpan(
                      text: AppLocalizations.of(context)!
                          .marketplaceScreenDescriptionBold,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 34.sp,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.h),
            //ANCHOR - Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 22.w,
                mainAxisSpacing: 25.h,
                childAspectRatio: 175 / 190,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                children: [
                  MarketplaceButton(
                    title: AppLocalizations.of(context)!
                        .marketplaceScreenBuyButton,
                    subtitle: AppLocalizations.of(context)!
                        .marketplaceScreenBuyButtonDescription,
                    icon: Svgs.marketplaceBuy,
                    onPressed: () async {
                      if (multipleOnramps) {
                        Navigator.of(context).pushNamed(
                          OnRampScreen.routeName,
                        );
                      } else {
                        final address =
                            await ref.read(bitcoinProvider).getReceiveAddress();
                        final uri = ref.read(meldUriProvider(address?.address));
                        if (context.mounted) {
                          Navigator.of(context)
                              .pushNamed(WebviewScreen.routeName,
                                  arguments: WebviewArguments(
                                    uri,
                                    AppLocalizations.of(context)!
                                        .buyWithFiatScreenTitle,
                                  ));
                        }
                      }
                    },
                  ),
                  MarketplaceButton(
                      title: AppLocalizations.of(context)!
                          .marketplaceScreenExchangeButton,
                      subtitle: AppLocalizations.of(context)!
                          .marketplaceScreenExchangeButtonDescription,
                      icon: Svgs.marketplaceExchange,
                      onPressed: () async {
                        Navigator.of(context).pushNamed(SwapScreen.routeName);
                      }),
                  MarketplaceButton(
                    title: AppLocalizations.of(context)!
                        .marketplaceScreenRemittanceButton,
                    subtitle: AppLocalizations.of(context)!
                        .marketplaceScreenRemittanceButtonDescription,
                    icon: Svgs.marketplaceRemittance,
                  ),
                  MarketplaceButton(
                    title: AppLocalizations.of(context)!
                        .marketplaceScreenBankingButton,
                    subtitle: AppLocalizations.of(context)!
                        .marketplaceScreenBankingButtonDescription,
                    icon: Svgs.marketplaceBankings,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 1.h,
            ),
            const MarketplaceBottomTextBox(),
            SizedBox(
              height: 4.h,
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceBottomTextBox extends StatelessWidget {
  const MarketplaceBottomTextBox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          // TODO: Add color in APP/Aqua Colors
          color: Theme.of(context).colorScheme.onInverseSurface),
      width: ScreenUtil().screenWidth,
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Center(
        child: RichText(
            text: TextSpan(
                text: AppLocalizations.of(context)!
                    .marketplaceScreenBottomBoxText,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 14.sp),
                children: [
              WidgetSpan(
                child: SizedBox(width: 6.w),
              ),
              TextSpan(
                  text: AppLocalizations.of(context)!
                      .marketplaceScreenBottomBoxTextBoldText,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      await launchUrl(Uri(
                        scheme: 'mailto',
                        path: aquaSupportEmail,
                        query: encodeQueryParameters(<String, String>{
                          'subject': 'AQUA Marketplace Feature Request',
                        }),
                      ));
                    },
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.secondary))
            ])),
      ),
    );
  }
}
