import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/address_validator/models/amount_parsing_exception.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SendGdkTransactor', () {
    test('throws on invalid bip21 amount', () async {
      final asset = Asset.lbtc();
      final args = SendAssetArguments.fromAsset(asset);
      const amountInSats = 1000;
      final mismatchedAmount = encodeBip21AmountFromSats(
        amountInSats: 2000,
        asset: asset,
      );
      final address =
          'liquidnetwork:fakeaddress?amount=$mismatchedAmount&assetid=${asset.id}';
      final input = SendAssetInputState(
        asset: asset,
        amount: amountInSats,
        amountFieldText: amountInSats.toString(),
        addressFieldText: address,
        rate: kBtcUsdExchangeRate,
      );
      final mockLiquidProvider = MockLiquidProvider();
      final mockFeeEstimateClient = MockFeeEstimateClient()
        ..mockGetLiquidFeeRate(1.0);
      final container = ProviderContainer(overrides: [
        liquidProvider.overrideWith((_) => mockLiquidProvider),
        feeEstimateProvider.overrideWith((_) => mockFeeEstimateClient),
      ]);

      final transactor = container.read(sendTransactionExecutorProvider(args));

      await expectLater(
        () => transactor.createTransaction(sendInput: input),
        throwsA(
          isA<AmountParsingException>().having(
            (e) => e.type,
            'type',
            AmountParsingExceptionType.invalidArguments,
          ),
        ),
      );
    });
  });
}
