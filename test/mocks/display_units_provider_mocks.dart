import 'package:aqua/features/wallet/wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:mocktail/mocktail.dart';

class MockDisplayUnitsProvider extends Mock implements DisplayUnitsProvider {}

extension MockDisplayUnitsProviderX on MockDisplayUnitsProvider {
  void mockSetCurrentDisplayUnit() {
    when(() => setCurrentDisplayUnit(any())).thenAnswer((_) async {});
  }

  void mockGetForcedDisplayUnit({required SupportedDisplayUnits value}) {
    when(() => getForcedDisplayUnit(any())).thenReturn(value);
  }

  void mockGetAssetDisplayUnit({required String value}) {
    when(() => getAssetDisplayUnit(
          any(),
          forcedDisplayUnit: any(named: 'forcedDisplayUnit'),
        )).thenReturn(value);
  }

  void mockSupportedDisplayUnits({required List<SupportedDisplayUnits> value}) {
    when(() => supportedDisplayUnits).thenReturn(value);
  }

  void mockCurrentDisplayUnit({required SupportedDisplayUnits value}) {
    when(() => currentDisplayUnit).thenReturn(value);
  }

  void mockConvertSatsToUnit({Decimal? value}) {
    when(() => convertSatsToUnit(
          sats: any(named: 'sats'),
          asset: any(named: 'asset'),
          displayUnitOverride: any(named: 'displayUnitOverride'),
        )).thenAnswer((invocation) {
      if (value != null) {
        return value;
      }
      // Default behavior: convert sats to display unit
      final sats = invocation.namedArguments[#sats] as int;
      final displayUnit = invocation.namedArguments[#displayUnitOverride]
          as SupportedDisplayUnits?;
      final satsPerUnit =
          displayUnit?.satsPerUnit ?? 100000000; // Default to BTC
      return (Decimal.fromInt(sats) / Decimal.fromInt(satsPerUnit)).toDecimal();
    });
  }

  void mockConvertUnitToSats({int? value}) {
    when(() => convertUnitToSats(
          amount: any(named: 'amount'),
          asset: any(named: 'asset'),
          displayUnitOverride: any(named: 'displayUnitOverride'),
        )).thenAnswer((invocation) {
      if (value != null) {
        return value;
      }
      // Default behavior: convert based on display unit
      final amount = invocation.namedArguments[#amount] as Decimal;
      final displayUnit = invocation.namedArguments[#displayUnitOverride]
          as SupportedDisplayUnits?;
      final satsPerUnit =
          displayUnit?.satsPerUnit ?? 100000000; // Default to BTC
      return (amount * Decimal.fromInt(satsPerUnit)).toBigInt().toInt();
    });
  }
}
