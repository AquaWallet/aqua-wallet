import 'package:aqua/features/lightning/models/bolt11_ext.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bolt11Ext.getAmountFromLightningInvoice', () {
    test('returns correct amount in sats for valid invoice', () {
      // This is a sample mainnet invoice for 0.00001 BTC (1000 sats)
      const validInvoice =
          'lnbc10u1pn7l5s8sp5wwzy3m5w26q3flj9xdxaakxmj0mqvq7sznml46ga7gyma7ucnj2spp5lfl7gdf7ucf4f8c22jwmrmd32k3ytevp73dg6czvl9fr5dkayqcqdpz2djkuepqw3hjqnpdgf2yxgrpv3j8yetnwvxqyp2xqcqz95rzjqg6jlc8vcxzf5ctp7e90qhccl6cyh3dl6ga5hqahwnzmq2svmat0qzzxeyqq28qqqqqqqqqqqqqqq9gq2y9qyysgqdd5thfunvacc5ed9w6zxdvg8rxvcvt9fhmv4ltwwn8z758cfsj64n9uksud5auk8cundkmt3yecg7qyjnfk4dwjah80krqafutqh5ecpgkeupe';

      final result = Bolt11Ext.getAmountFromLightningInvoice(validInvoice);

      expect(result, isNotNull);
      expect(result, equals(1000));
    });

    test('handles lightning: prefix correctly', () {
      const invoiceWithPrefix =
          'lightning:lnbc10u1pn7l5s8sp5wwzy3m5w26q3flj9xdxaakxmj0mqvq7sznml46ga7gyma7ucnj2spp5lfl7gdf7ucf4f8c22jwmrmd32k3ytevp73dg6czvl9fr5dkayqcqdpz2djkuepqw3hjqnpdgf2yxgrpv3j8yetnwvxqyp2xqcqz95rzjqg6jlc8vcxzf5ctp7e90qhccl6cyh3dl6ga5hqahwnzmq2svmat0qzzxeyqq28qqqqqqqqqqqqqqq9gq2y9qyysgqdd5thfunvacc5ed9w6zxdvg8rxvcvt9fhmv4ltwwn8z758cfsj64n9uksud5auk8cundkmt3yecg7qyjnfk4dwjah80krqafutqh5ecpgkeupe';

      final result = Bolt11Ext.getAmountFromLightningInvoice(invoiceWithPrefix);

      expect(result, isNotNull);
      expect(result, equals(1000));
    });

    test('handles LIGHTNING: prefix with mixed case correctly', () {
      const invoiceWithMixedCasePrefix =
          'LIGHTNING:lnbc10u1pn7l5s8sp5wwzy3m5w26q3flj9xdxaakxmj0mqvq7sznml46ga7gyma7ucnj2spp5lfl7gdf7ucf4f8c22jwmrmd32k3ytevp73dg6czvl9fr5dkayqcqdpz2djkuepqw3hjqnpdgf2yxgrpv3j8yetnwvxqyp2xqcqz95rzjqg6jlc8vcxzf5ctp7e90qhccl6cyh3dl6ga5hqahwnzmq2svmat0qzzxeyqq28qqqqqqqqqqqqqqq9gq2y9qyysgqdd5thfunvacc5ed9w6zxdvg8rxvcvt9fhmv4ltwwn8z758cfsj64n9uksud5auk8cundkmt3yecg7qyjnfk4dwjah80krqafutqh5ecpgkeupe';

      final result =
          Bolt11Ext.getAmountFromLightningInvoice(invoiceWithMixedCasePrefix);

      expect(result, isNotNull);
      expect(result, equals(1000));
    });

    test('handles invoice with mixed case correctly', () {
      const mixedCaseInvoice =
          'LNBC25M1PVJLUEZPP5QQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQYPQDQ5VDHKVEN9V5SXYETPDEESSP5ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYGS9Q5SQQQQQQQQQQQQQQQQSGQ2A25DXL5HRNTDTN6ZVYDT7D66HYZSYHQS4WDYNAVYS42XGL6SGX9C4G7ME86A27T07MDTFRY458RTJR0V92CNMSWPSJSCGT2VCSE3SGPZ3UAPA';

      final result = Bolt11Ext.getAmountFromLightningInvoice(mixedCaseInvoice);

      expect(result, isNotNull);
      expect(result, equals(2500000));
    });

    test('returns null for invalid invoice', () {
      const invalidInvoice = 'invalid_invoice_string';

      final result = Bolt11Ext.getAmountFromLightningInvoice(invalidInvoice);

      expect(result, isNull);
    });

    test('returns null for empty string', () {
      const emptyInvoice = '';

      final result = Bolt11Ext.getAmountFromLightningInvoice(emptyInvoice);

      expect(result, isNull);
    });

    test('returns null for malformed lightning prefix', () {
      const malformedInvoice = 'lightning:invalid_invoice';

      final result = Bolt11Ext.getAmountFromLightningInvoice(malformedInvoice);

      expect(result, isNull);
    });

    test('handles different amount values correctly', () {
      const smallAmountInvoice =
          'lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh';

      final result =
          Bolt11Ext.getAmountFromLightningInvoice(smallAmountInvoice);

      expect(result, isNotNull);
      expect(result, equals(250000));
    });

    test('handles invoice without amount (amount = 0)', () {
      // Sample invoice without amount specified
      const noAmountInvoice =
          'lnbc1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq9qrsgq357wnc5r2ueh7ck6q93dj32dlqnls087fxdwk8qakdyafkq3yap9us6v52vjjsrvywa6rt52cm9r9zqt8r2t7mlcwspyetp5h2tztugp9lfyql';

      final result = Bolt11Ext.getAmountFromLightningInvoice(noAmountInvoice);

      expect(result, isNotNull);
      expect(result, equals(0));
    });
  });
}
