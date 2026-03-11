import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/features/shared/providers/btc_price_provider.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:decimal/decimal.dart';

extension Bolt11Ext on Bolt11PaymentRequest {
  static int? getAmountFromLightningInvoice(String invoice) {
    try {
      final lowercaseInvoice = invoice.toLowerCase();
      final cleanInvoice = lowercaseInvoice.startsWith('lightning:')
          ? lowercaseInvoice.substring('lightning:'.length)
          : lowercaseInvoice;

      return (Bolt11PaymentRequest(cleanInvoice).amount *
              Decimal.fromInt(satsPerBtc))
          .toInt();
    } catch (_) {
      return null;
    }
  }
}
