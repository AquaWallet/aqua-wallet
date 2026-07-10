import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/depix/models/models.dart';
import 'package:aqua/features/settings/experimental/providers/experimental_features_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:chopper/chopper.dart';
import 'package:http/io_client.dart' as http;

part 'jan3_api_depix.chopper.dart';

final jan3ApiDepixProvider = Provider.autoDispose<Jan3ApiDepix>((ref) {
  final walletId = ref.watch(currentWalletIdSyncProvider);
  final onUnauthorized =
      ref.read(jan3AuthProvider(walletId).notifier).onUnauthorized;
  final tokenManager = ref.watch(jan3AuthTokenManagerProvider(walletId));
  final jan3StagingEnabled =
      ref.read(featureFlagsProvider.select((p) => p.jan3StagingEnabled));
  return Jan3ApiDepix.create(tokenManager, onUnauthorized, jan3StagingEnabled);
});

@ChopperApi(baseUrl: '/api/')
abstract class Jan3ApiDepix extends ChopperService {
  @Post(path: 'v1/eulen/deposit/')
  Future<Response<EulenDepositResponse>> deposit(
    @Body() EulenDepositRequest request,
  );

  @Get(path: 'v1/eulen/deposits/')
  Future<Response<EulenDepositsResponse>> getDeposits();

  @Get(path: 'v1/eulen/pix-depix-fee/')
  Future<Response<EulenFeeCalculation>> calculateFeeFromGross(
    @Query('gross_amount_brl_cents') int grossAmountBrlCents,
  );

  @Get(path: 'v1/eulen/pix-depix-fee/')
  Future<Response<EulenFeeCalculation>> calculateFeeFromNet(
    @Query('net_amount_brl_cents') int netAmountBrlCents,
  );

  static Jan3ApiDepix create(
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
      services: [_$Jan3ApiDepix()],
      interceptors: [
        HttpLoggingInterceptor(),
        Jan3ApiAuthInterceptor(tokenManager),
        Jan3ApiResponseInterceptor(onUnauthorized),
      ],
      errorConverter: const JsonConverter(),
      converter: const JsonToTypeConverter({
        EulenDepositResponse: EulenDepositResponse.fromJson,
        EulenDepositsResponse: EulenDepositsResponse.fromJson,
        EulenFeeCalculation: EulenFeeCalculation.fromJson,
      }),
    );
    return _$Jan3ApiDepix(client);
  }
}
