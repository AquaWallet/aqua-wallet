import 'dart:convert';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';

part 'marketplace_service.chopper.dart';

class MarketplaceJsonConverter extends JsonToTypeConverter {
  const MarketplaceJsonConverter(super.typeToJsonFactoryMap);

  @override
  Response<BodyType> convertResponse<BodyType, InnerType>(Response response) {
    final bodyString = utf8.decode(response.bodyBytes);
    return response.copyWith(
      body: fromJsonData<BodyType, InnerType>(
        bodyString,
        typeToJsonFactoryMap[InnerType]!,
      ),
    );
  }
}

final marketplaceServiceProvider =
    Provider.autoDispose<MarketplaceService>((ref) {
  final debitCardStagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.debitCardStagingEnabled));
  return MarketplaceService.create(
    debitCardStagingEnabled: debitCardStagingEnabled,
  );
});

@ChopperApi(baseUrl: '/api/v1/marketplace/')
abstract class MarketplaceService extends ChopperService {
  @Get(path: 'tiles')
  Future<Response<List<ServiceTilesResponse>>> getMarketPlaceTiles({
    @Query('build') String? buildNumber,
    @Query('os') String? os,
  });

  @Get(path: 'regions')
  Future<Response<RegionResponse>> fetchRegions();

  @Get(path: 'assets')
  Future<Response<AssetsResponse>> fetchAssets();

  @Get(path: 'assets/testnet')
  Future<Response<AssetsResponse>> fetchTestNetAssets();

  static MarketplaceService create({
    required bool debitCardStagingEnabled,
  }) {
    final client = ChopperClient(
        baseUrl: Uri.parse(debitCardStagingEnabled
            ? aquaAnkaraStagingApiUrl
            : aquaAnkaraProdApiUrl),
        services: [_$MarketplaceService()],
        interceptors: [HttpLoggingInterceptor()],
        errorConverter: const JsonConverter(),
        converter: const MarketplaceJsonConverter({
          Region: Region.fromJson,
          RegionResponse: RegionResponse.fromJson,
          AssetsResponse: AssetsResponse.fromJson,
          ServiceTilesResponse: ServiceTilesResponse.fromJson
        }));

    return _$MarketplaceService(client);
  }
}
