import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';

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
