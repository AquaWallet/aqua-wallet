import 'package:coin_cz/common/decimal/decimal_ext.dart';
import 'package:coin_cz/features/shared/providers/btc_price_provider.dart';
import 'package:coin_cz/logger.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:decimal/decimal.dart';

extension Bolt11Ext on Bolt11PaymentRequest {
  static int? getAmountFromLightningInvoice(String invoice) {
    try {
      String processedInput = invoice.toLowerCase();
      if (processedInput.startsWith('lightning:')) {
        processedInput = processedInput.substring('lightning:'.length);
      }
      final result = Bolt11PaymentRequest(processedInput);
      final amount = (result.amount *
          Decimal.fromInt(
              satsPerBtc)); // Bolt11PaymentRequest returns amount in BTC, so convert to sats
      return amount.toInt();
    } catch (_) {
      logger.debug("[Boltz] Could not parse amount from invoice");
      return null;
    }
  }
}
