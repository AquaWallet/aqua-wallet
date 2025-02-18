import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/marketplace/models/on_ramp_regions_integrations.dart';
import 'package:aqua/features/settings/exchange_rate/exchange_rate.dart';
import 'package:aqua/features/settings/region/models/region.dart';

import 'models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'on_ramp_integration.freezed.dart';
part 'on_ramp_integration.g.dart';

enum OnRampIntegrationType {
  beaverBitcoin,
  pocketBitcoin,
  btcDirect,
  meld,
  elektra
}

@freezed
class OnRampIntegration with _$OnRampIntegration {
  const factory OnRampIntegration({
    required String name,
    required String logoLight,
    required String logoDark,
    required OnRampIntegrationType type,
    required List<PaymentOption> paymentOptions,
    required List<DeliveryOption> deliveryOptions,
    required List<Region> regions,
    required bool allRegions,
    // launch the integration in an external browser or not
    // for integrations where we don't pass a receive address, we want to launch in an external browser so the user can flip back to aqua to generate a receive address
    required bool openInBrowser,
    // indicates if an integration needs setup, e.g. BTC Direct needs user registration
    // we can create a smoother u/x by setting up on first launch in flow
    required bool needsSetup,
    String? refLinkMainnet,
    String? refLinkTestnet,
    required bool hasPriceApi,
    String? priceApi,
    String? priceSymbol,
    String? priceCurrencyCode,
  }) = _OnRampIntegration;

  factory OnRampIntegration.fromJson(Map<String, dynamic> json) =>
      _$OnRampIntegrationFromJson(json);

  // All instances
  // NOTE: Order is a product decision - Order here determines order in UI
  static List<OnRampIntegration> get allIntegrations => [
        OnRampIntegration.beaverBitcoin(),
        OnRampIntegration.pocketBitcoin(),
        OnRampIntegration.btcDirect(),
        OnRampIntegration.meld(),
      ];

  // Static instances
  factory OnRampIntegration.beaverBitcoin() => OnRampIntegration(
        name: 'Beaver Bitcoin',
        logoLight: SvgsMarketplace.beaverBlack,
        logoDark: SvgsMarketplace.beaverWhite,
        type: OnRampIntegrationType.beaverBitcoin,
        paymentOptions: [PaymentOption.bankTransfer, PaymentOption.creditCard],
        deliveryOptions: [DeliveryOption.btc],
        regions: [RegionsStatic.ca],
        allRegions: false,
        openInBrowser: true,
        needsSetup: false,
        refLinkMainnet: 'https://www.beaverbitcoin.com/aqua/',
        refLinkTestnet: 'https://dev.beaverbitcoin.com',
        hasPriceApi: true,
        priceApi: 'https://api.prod.beaverbitcoin.com/bitcoin/price',
        priceSymbol: FiatCurrency.cad.symbol,
        priceCurrencyCode: FiatCurrency.cad.value,
      );

  factory OnRampIntegration.pocketBitcoin() => OnRampIntegration(
        name: 'Pocket Bitcoin',
        logoLight: SvgsMarketplace.pocketBlack,
        logoDark: SvgsMarketplace.pocketWhite,
        type: OnRampIntegrationType.pocketBitcoin,
        paymentOptions: [PaymentOption.bankTransfer, PaymentOption.creditCard],
        deliveryOptions: [DeliveryOption.btc],
        regions: RegionsIntegrations.pocketBitcoinRegions,
        allRegions: false,
        openInBrowser: true,
        needsSetup: false,
        refLinkMainnet: 'https://pocketbitcoin.com/invite/jan3',
        refLinkTestnet: '',
        hasPriceApi: true,
        priceApi:
            'https://api.kraken.com/0/public/Ticker?pair=XBTEUR', // they use kraken for price
        priceSymbol: FiatCurrency.eur.symbol,
        priceCurrencyCode: FiatCurrency.eur.value,
      );

  factory OnRampIntegration.btcDirect() => OnRampIntegration(
        name: 'BTC Direct',
        logoLight: SvgsMarketplace.btcDirectBlack,
        logoDark: SvgsMarketplace.btcDirectWhite,
        type: OnRampIntegrationType.btcDirect,
        paymentOptions: [
          PaymentOption.bankTransfer,
          PaymentOption.creditCard
        ], //TODO: BTC Direct supports more payment options, such as Apple Pay, iDEAL, Bancontact, Sofort, Cartes Bancaires, etc. Add logos later
        deliveryOptions: [DeliveryOption.btc],
        regions: RegionsIntegrations.btcDirectRegions,
        allRegions: false,
        openInBrowser: false,
        needsSetup: true,
        refLinkMainnet:
            null, // NOTE: This is dynamic from API. See BTCDirectApiService.createCheckoutUrl()
        refLinkTestnet:
            null, // NOTE: This is dynamic from API. See BTCDirectApiService.createCheckoutUrl()
        hasPriceApi: true,
        priceApi:
            null, // NOTE: Use BTCDirectApiService.getBTCPrice() as we need to be authed
        priceSymbol: FiatCurrency.eur.symbol,
        priceCurrencyCode: FiatCurrency.eur.value,
      );

  //NOTE: There are extensive Meld testing docs here: https://docs.meld.io/docs/crypto-testing-guide
  factory OnRampIntegration.meld() => const OnRampIntegration(
      name: 'Meld',
      logoLight: SvgsMarketplace.meldBlack,
      logoDark: SvgsMarketplace.meldWhite,
      type: OnRampIntegrationType.meld,
      paymentOptions: [PaymentOption.bankTransfer, PaymentOption.creditCard],
      deliveryOptions: [DeliveryOption.btc],
      regions: [],
      allRegions: true,
      openInBrowser: false,
      needsSetup: false,
      hasPriceApi: false,
      refLinkMainnet: meldProdUrl,
      refLinkTestnet: meldSandboxUrl);
}
