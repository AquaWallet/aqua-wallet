import 'package:coin_cz/features/marketplace/models/models.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:dio/dio.dart';

final _logger = CustomLogger(FeatureFlag.onramp);

abstract class OnRampPriceFetcher {
  Future<String?> fetchPrice(OnRampIntegration integration, Ref ref);
}

class PublicApiPriceFetcher implements OnRampPriceFetcher {
  final Dio _client;

  PublicApiPriceFetcher(this._client);

  @override
  Future<String?> fetchPrice(OnRampIntegration integration, Ref ref) async {
    final uri = integration.priceApi;
    if (uri == null) {
      _logger.debug('No price API for ${integration.name}');
      return null;
    }

    try {
      _logger.debug('Fetching price for ${integration.name} from $uri');
      final response = await _client.get(uri);

      switch (integration.type) {
        case OnRampIntegrationType.beaverBitcoin:
          final data = response.data;
          final priceInCents = data['priceInCents'] as int;
          final price = (priceInCents / 100);
          final formatter = ref.read(currencyFormatProvider(0));
          final formattedPrice =
              "${integration.priceSymbol}${formatter.format(price)}";
          _logger
              .debug('Fetched price for ${integration.name}: $formattedPrice');
          return formattedPrice;

        case OnRampIntegrationType.pocketBitcoin:
          final data = response.data;
          final result = data['result']['XXBTZEUR'];
          final price = double.parse(result['a'][0]);
          final formatter = ref.read(currencyFormatProvider(0));
          final formattedPrice =
              "${integration.priceSymbol}${formatter.format(price)}";
          _logger
              .debug('Fetched price for ${integration.name}: $formattedPrice');
          return formattedPrice;

        default:
          _logger.debug('No price fetcher for ${integration.name}');
          return null;
      }
    } on DioException catch (e) {
      _logger
          .error('Error fetching price for ${integration.name}: ${e.message}');
      rethrow;
    }
  }
}
