import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReceiveAssetAddressQrCard', () {
    Widget buildTestableWidget({
      required Asset asset,
      required String address,
      SwapOrder? swapOrder,
      SwapPair? swapPair,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReceiveAssetAddressQrCard(
            asset: asset,
            address: address,
            swapOrder: swapOrder,
            swapPair: swapPair,
          ),
        ),
      );
    }

    group('Single Use Address Label', () {
      testWidgets(
          'Sideshift order shows single use address label and expiry date',
          (tester) async {
        // Arrange - Create a Sideshift order with expiry date
        final swapOrder = SwapOrder(
          createdAt: DateTime.now(),
          id: 'test_sideshift_order',
          from: SwapAssetExt.usdtEth,
          to: SwapAssetExt.usdtLiquid,
          depositAddress: '0xDepositAddress',
          settleAddress: 'lq1SettleAddress',
          depositAmount: Decimal.parse('100'),
          settleAmount: Decimal.parse('99'),
          serviceFee: SwapFee(
            type: SwapFeeType.flatFee,
            value: Decimal.parse('1'),
            currency: SwapFeeCurrency.usd,
          ),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          status: SwapOrderStatus.waiting,
          serviceType: SwapServiceSource.sideshift,
        );

        final swapPair = SwapPair(
          from: SwapAssetExt.usdtEth,
          to: SwapAssetExt.usdtLiquid,
        );

        // Act
        await tester.pumpWidget(buildTestableWidget(
          asset: Asset.usdtEth(),
          address: '0xDepositAddress',
          swapOrder: swapOrder,
          swapPair: swapPair,
        ));

        await tester.pumpAndSettle();

        // Assert - Both label and expiry should be present
        expect(find.byType(SingleUseReceiveAddressLabel), findsOneWidget);
        expect(find.textContaining('Exp'), findsOneWidget);
      });

      testWidgets(
          'Changelly variable order shows single use address label without expiry date',
          (tester) async {
        // Arrange - Create a Changelly variable order with null expiry (simulating the bug scenario)
        final swapOrder = SwapOrder(
          createdAt: DateTime.now(),
          id: 'test_changelly_order',
          from: SwapAssetExt.usdtEth,
          to: SwapAssetExt.usdtLiquid,
          depositAddress: '0xDepositAddress',
          settleAddress: 'lq1SettleAddress',
          depositAmount: Decimal.parse('100'),
          settleAmount: Decimal.parse('99'),
          serviceFee: SwapFee(
            type: SwapFeeType.flatFee,
            value: Decimal.parse('1'),
            currency: SwapFeeCurrency.usd,
          ),
          expiresAt:
              null, // This is the key difference - Changelly variable orders have no expiry
          status: SwapOrderStatus.waiting,
          serviceType: SwapServiceSource.changelly,
        );

        final swapPair = SwapPair(
          from: SwapAssetExt.usdtEth,
          to: SwapAssetExt.usdtLiquid,
        );

        // Act
        await tester.pumpWidget(buildTestableWidget(
          asset: Asset.usdtEth(),
          address: '0xDepositAddress',
          swapOrder: swapOrder,
          swapPair: swapPair,
        ));

        await tester.pumpAndSettle();

        // Assert - Label should be present, but expiry should NOT be
        expect(find.byType(SingleUseReceiveAddressLabel), findsOneWidget);
        expect(find.textContaining('Exp'), findsNothing);
      });

      testWidgets(
          'Regular receive (non-USDT) does not show single use address label',
          (tester) async {
        // Act - No swapPair means no swap UI should show
        await tester.pumpWidget(buildTestableWidget(
          asset: Asset.btc(),
          address: 'bc1qMockAddress',
        ));

        await tester.pumpAndSettle();

        // Assert - No swap-related elements should be present
        expect(find.byType(SingleUseReceiveAddressLabel), findsNothing);
        expect(find.byType(AltUsdtNetworkWarningChip), findsNothing);
        expect(find.textContaining('Exp'), findsNothing);
      });
    });
  });
}
