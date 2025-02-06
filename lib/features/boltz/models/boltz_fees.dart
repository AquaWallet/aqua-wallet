import 'package:aqua/features/lightning/models/bolt11_ext.dart';

// These fees are DiscountCT fees (unless marked "legacy")
const kBoltzLiquidLockupTxFee =
    31; // TODO: Revise if correct. Was 26 for lowball. This is the upwards estimate for discountCT.
const kBoltzLiquidClaimTxFee = 19;
const kBoltzLiquidRefundTxFee = 19;
// for non-coop, tx is slightly bigger, and the absolute fee is higher (if boltz doesn't change the taptree, but there will be other errors if that happens)
// ignore: constant_identifier_names
const kBoltzLiquidClaimTxFee_NonCoop = 23;
const kBoltzLiquidLockupTxFeeLegacy = 276;
const kBoltzLiquidClaimTxFeeLegacy = 152;
const kBoltzReversePercentFee = 0.0025; // 0.25%
const kBoltzSubmarinePercentFee = 0.001; // 0.1%

class BoltzFees {
  //ANCHOR: Submarine
  static int get totalTxFeesSubmarine {
    return kBoltzLiquidLockupTxFee + kBoltzLiquidClaimTxFee;
  }

  // boltz service fee and boltz claim fee (doesn't include the lockup tx fee which we send)
  static int serviceFeesForAmountSubmarine(int amount) {
    return serviceFeeSubmarine(amount) + kBoltzLiquidClaimTxFee;
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesSubmarine(String invoice) {
    final invoiceAmount = Bolt11Ext.getAmountFromLightningInvoice(invoice);
    if (invoiceAmount == null) {
      return 0;
    }

    return serviceFeesForAmountSubmarine(invoiceAmount);
  }

  static int serviceFeeSubmarine(int amount) {
    return (amount * kBoltzSubmarinePercentFee).ceil();
  }

  //ANCHOR: Reverse
  static int get totalTxFeesReverse {
    return kBoltzLiquidLockupTxFee +
        kBoltzLiquidClaimTxFee; // assume lowball on our end
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesForAmountReverse(int amount) {
    return serviceFeeReverse(amount) + totalTxFeesReverse;
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesReverse(String invoice) {
    final invoiceAmount = Bolt11Ext.getAmountFromLightningInvoice(invoice);
    if (invoiceAmount == null) {
      return 0;
    }

    return totalFeesForAmountReverse(invoiceAmount);
  }

  static int serviceFeeReverse(int amount) {
    return (amount * kBoltzReversePercentFee).ceil();
  }
}
