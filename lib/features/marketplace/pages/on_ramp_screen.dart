import 'package:aqua/config/config.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/models/on_ramp_price.dart';
import 'package:aqua/features/marketplace/providers/providers.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = CustomLogger(FeatureFlag.onramp);

class OnRampScreen extends HookConsumerWidget {
  const OnRampScreen({super.key});
  static const routeName = '/onRampScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onRampOptions = ref.watch(onRampOptionsProvider);

    // setup btc direct api service if btc direct is enabled
    final btcDirectEnabled = useMemoized(
        () => onRampOptions.any(
              (option) => option.type == OnRampIntegrationType.btcDirect,
            ),
        [onRampOptions]);
    if (btcDirectEnabled) {
      ref.watch(btcDirectApiServiceProvider);
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onRampSetupProvider.notifier).setupIntegrations(onRampOptions);
      });
      return null;
    }, [onRampOptions]);

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
                  fontSize: 16.0,
                  color: Theme.of(context).colors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              itemCount: onRampOptions.length,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 32.0,
              ),
              separatorBuilder: (_, index) => const SizedBox(height: 22.0),
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

    final referencePrice =
        ref.watch(btcPriceProvider(0)).unwrapPrevious().valueOrNull;

    final price = useCallback(() {
      if (integration.hasPriceApi) {
        return OnRampPrice(
            currencyCode: integration.priceCurrencyCode ?? "",
            price: integrationPrice ?? "",
            type: OnRampPriceType.integration);
      } else {
        return OnRampPrice(
          currencyCode: referencePrice?.value?.currency.value ?? "",
          price: referencePrice?.value?.priceWithSymbol ?? "",
          type: OnRampPriceType.reference,
        );
      }
    }, [integrationPrice, referencePrice]);

    final launchIntegration =
        useCallback((OnRampIntegration integration) async {
      try {
        final url = await ref
            .read(onRampSetupProvider.notifier)
            .getIntegrationUrl(integration);
        final uri = Uri.parse(url);

        if (integration.openInBrowser) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            context.push(
              WebviewScreen.routeName,
              extra: WebviewArguments(
                uri,
                context.loc.buyWithFiatScreenTitle,
              ),
            );
          }
        }
      } catch (e) {
        _logger.error('Failed to launch integration: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.loc.unknownErrorSubtitle)),
          );
        }
      }
    }, []);

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20.0),
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: () => launchIntegration(integration),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(18.0),
          child: Container(
            height: 140.0,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //ANCHOR - Logo
                      SvgPicture.asset(
                        darkMode ? integration.logoDark : integration.logoLight,
                        fit: BoxFit.contain,
                        height:
                            context.adaptiveDouble(smallMobile: 24, mobile: 28),
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
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 4.0),
                          //ANCHOR - BTC Price Currency Code
                          Text(
                            "(${price().currencyCode})",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      //ANCHOR - BTC Price
                      Skeletonizer(
                          enabled: price().price == "",
                          child: Text(
                            price().price == "" ? "xxxxxxx" : price().price,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: context.adaptiveDouble(
                                      smallMobile: 24, mobile: 26),
                                ),
                          )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    //ANCHOR - Payment Options Label
                    Text(
                      context.loc.onrampScreenPaymentOptionsLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    //ANCHOR - Payment Options Items
                    const SizedBox(height: 4.0),
                    SizedBox(
                      height: 20.0,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: integration.paymentOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                        itemBuilder: (_, index) {
                          final option = integration.paymentOptions[index];
                          return SvgPicture.asset(
                            option.icon,
                            width: 20.0,
                            height: 20.0,
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    //ANCHOR - Delivery Options Label
                    Text(
                      context.loc.onrampScreenDeliveryOptionsLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    //ANCHOR - Delivery Options Items
                    SizedBox(
                      height: 20.0,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: integration.deliveryOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                        itemBuilder: (_, index) {
                          final option = integration.deliveryOptions[index];
                          return SvgPicture.asset(
                            option.logo,
                            width: 20.0,
                            height: 20.0,
                          );
                        },
                      ),
                    ),
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
