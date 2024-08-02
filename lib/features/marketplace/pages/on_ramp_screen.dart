import 'package:aqua/config/config.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/models/on_ramp_price.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class OnRampScreen extends ConsumerWidget {
  const OnRampScreen({super.key});
  static const routeName = '/onRampScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onRampOptions = ref.watch(onRampOptionsProvider);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.onrampScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: onRampOptions.isEmpty
          ? Center(
              child: Text(
                context.loc.noOnrampOptionsAvailable,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: onRampOptions.length,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 28.w,
                vertical: 32.h,
              ),
              separatorBuilder: (_, index) => SizedBox(height: 22.h),
              itemBuilder: (_, index) =>
                  OnRampOptionCard(integration: onRampOptions[index]),
            ),
    );
  }
}

class OnRampOptionCard extends HookConsumerWidget {
  const OnRampOptionCard({
    super.key,
    required this.integration,
  });

  final OnRampIntegration integration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    final integrationPrice =
        ref.watch(onRampPriceProvider(integration)).valueOrNull;

    final referencePrice = ref.watch(btcPriceProvider(0)).valueOrNull;

    final price = useCallback(() {
      if (integration.priceApi != null) {
        return OnRampPrice(
            currencyCode: integration.priceCurrencyCode ?? "",
            price: integrationPrice ?? "",
            type: OnRampPriceType.integration);
      } else {
        return OnRampPrice(
          currencyCode: referencePrice?.currency.value ?? "",
          price: referencePrice?.priceWithSymbol ?? "",
          type: OnRampPriceType.reference,
        );
      }
    }, [integrationPrice, referencePrice]);

    Future<void> launchIntegration(String url, bool openInBrowser) async {
      final Uri uri = Uri.parse(url);
      if (openInBrowser) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
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
    }

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () async {
            final uri = await ref
                .read(onRampOptionsProvider.notifier)
                .formattedUri(integration);
            launchIntegration(uri.toString(), integration.openInBrowser);
          },
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            height: 140.h,
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            child: Row(
              children: [
                SizedBox(
                  width: 200.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      //ANCHOR - Logo
                      SvgPicture.asset(
                        darkMode ? integration.logoDark : integration.logoLight,
                        fit: BoxFit.contain,
                        height: 28.r,
                      ),
                      // ),
                      const Spacer(),
                      Row(
                        children: [
                          //ANCHOR - BTC Price Label
                          Text(
                            context.loc.onrampScreenBtcPriceLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(width: 4.w),
                          //ANCHOR - BTC Price Currency Code
                          Text(
                            "(${price().currencyCode})",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      //ANCHOR - BTC Price
                      Text(
                        price().price,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 26.sp,
                            ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 20.h),
                    //ANCHOR - Payment Options Label
                    Text(
                      context.loc.onrampScreenPaymentOptionsLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    //ANCHOR - Payment Options Items
                    SizedBox(height: 4.h),
                    SizedBox(
                      height: 20.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: integration.paymentOptions.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (_, index) {
                          final option = integration.paymentOptions[index];
                          return SvgPicture.asset(
                            option.icon,
                            width: 20.r,
                            height: 20.r,
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    //ANCHOR - Delivery Options Label
                    Text(
                      context.loc.onrampScreenDeliveryOptionsLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    //ANCHOR - Delivery Options Items
                    SizedBox(
                      height: 20.h,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: integration.deliveryOptions.length,
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (_, index) {
                          final option = integration.deliveryOptions[index];
                          return SvgPicture.asset(
                            option.logo,
                            width: 20.r,
                            height: 20.r,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
