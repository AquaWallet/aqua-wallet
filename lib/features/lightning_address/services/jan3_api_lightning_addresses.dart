import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';
import 'package:http/io_client.dart' as http;

part 'jan3_api_lightning_addresses.chopper.dart';

final jan3ApiLightningAddressesProvider =
    Provider.autoDispose<Jan3ApiLightningAddresses>((ref) {
  final walletId = ref.watch(currentWalletIdSyncProvider);
  final onUnauthorized =
      ref.read(jan3AuthProvider(walletId).notifier).onUnauthorized;
  final tokenManager = ref.watch(jan3AuthTokenManagerProvider(walletId));
  final jan3StagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.jan3StagingEnabled));
  return Jan3ApiLightningAddresses.create(
      tokenManager, onUnauthorized, jan3StagingEnabled);
});

@ChopperApi(baseUrl: '/api/')
abstract class Jan3ApiLightningAddresses extends ChopperService {
  @Get(path: 'v1/auth/user/ln-username/{username}/is-available')
  Future<Response<IsLnUsernameAvailableResponse>> isLnUsernameAvailable(
    @Path('username') String username,
  );

  @Post(path: 'v1/auth/user/addresses/')
  Future<Response> registerAddresses(
    @Body() RegisterAddressesRequest request, {
    @Query('override_fingerprint') bool overrideFingerprint = false,
  });

  @Post(path: 'v1/liquid-wallet/payment-request/ln-username/')
  Future<Response<PaymentResponse>> createPaymentRequest(
    @Body() PaymentRequest request,
  );

  @Get(path: 'v1/liquid-wallet/products/')
  Future<Response<List<LiquidWalletProduct>>> getProducts(
    @Query('product_type') String productType,
  );

  @Post(path: 'v1/liquid-wallet/payment/submit-raw-tx/')
  Future<Response> submitRawTx(
    @Body() SubmitSignedTxRequest request,
  );

  static Jan3ApiLightningAddresses create(
    Jan3AuthTokenManager tokenManager,
    VoidCallback onUnauthorized,
    bool jan3StagingEnabled,
  ) {
    final client = ChopperClient(
      client: http.IOClient(
        HttpClient()..connectionTimeout = const Duration(seconds: 10),
      ),
      baseUrl: Uri.parse(
          jan3StagingEnabled ? aquaAnkaraStagingApiUrl : aquaAnkaraProdApiUrl),
      services: [_$Jan3ApiLightningAddresses()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(tokenManager),
        Jan3ApiResponseInterceptor(onUnauthorized),
      ],
      errorConverter: const JsonConverter(),
      converter: const JsonToTypeConverter({
        IsLnUsernameAvailableResponse: IsLnUsernameAvailableResponse.fromJson,
        PaymentResponse: PaymentResponse.fromJson,
        LiquidWalletProduct: LiquidWalletProduct.fromJson,
      }),
    );
    return _$Jan3ApiLightningAddresses(client);
  }
}
