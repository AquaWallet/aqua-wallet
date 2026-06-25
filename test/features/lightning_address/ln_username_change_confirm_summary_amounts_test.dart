import 'package:aqua/features/lightning_address/utils/ln_username_change_confirm_summary_amounts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lnUsernameChangeConfirmSummaryLines', () {
    test('payWithLbtc shows L-BTC numeric on crypto line and USD line on fiat',
        () {
      final r = lnUsernameChangeConfirmSummaryLines(
        payWithLbtc: true,
        lbtcAmountNumericOnly: '0.00001',
        usdtAmountDisplay: '12.34',
        lbtcLineWithDisplayUnit: '0.00001 L-BTC',
        usdtLineWithSymbol: r'$12.34',
      );
      expect(r.amountCrypto, '-0.00001');
      expect(r.amountFiat, r'-$12.34');
    });

    test(
        'payWithUsdt shows USDT display on crypto line and L-BTC line with unit on fiat',
        () {
      final r = lnUsernameChangeConfirmSummaryLines(
        payWithLbtc: false,
        lbtcAmountNumericOnly: '0.00001',
        usdtAmountDisplay: '12.34',
        lbtcLineWithDisplayUnit: '0.00001 L-BTC',
        usdtLineWithSymbol: r'$12.34',
      );
      expect(r.amountCrypto, '-12.34');
      expect(r.amountFiat, '-0.00001 L-BTC');
    });
  });
}
