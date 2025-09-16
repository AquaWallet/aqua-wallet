import 'package:coin_cz/features/marketplace/marketplace.dart';
import 'package:coin_cz/features/private_integrations/private_integrations.dart';
import 'package:coin_cz/features/shared/shared.dart';

class OnRampPriceFetcherFactory {
  static OnRampPriceFetcher create(OnRampIntegrationType type, Ref ref) {
    switch (type) {
      case OnRampIntegrationType.btcDirect:
        return BTCDirectPriceFetcher(ref.read(btcDirectApiServiceProvider
            as ProviderListenable<BTCDirectApiService>));
      default:
        return PublicApiPriceFetcher(ref.read(dioProvider));
    }
  }
}
