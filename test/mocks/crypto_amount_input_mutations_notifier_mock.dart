import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:mocktail/mocktail.dart';

class MockCryptoAmountInputMutationsNotifier extends Mock
    implements CryptoAmountInputMutationsNotifier {
  @override
  Future<String?> getConvertedAmount({
    required int amountSats,
    required Asset asset,
    bool? isFiatAmountInput,
    bool withSymbol = true,
    SupportedDisplayUnits? displayUnitOverride,
  }) async {
    // Return a simple mock conversion
    if (amountSats == 0) return null;
    final amount = (amountSats / 100000000 * 56690);
    final formattedAmount = amount.toStringAsFixed(2);
    // Add thousands separator for amounts >= 1000
    final parts = formattedAmount.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }

    final finalAmount = '$formattedInteger.$decimalPart';
    return withSymbol ? '\$$finalAmount' : finalAmount;
  }
}
