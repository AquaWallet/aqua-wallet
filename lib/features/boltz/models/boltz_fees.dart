import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/features/lightning/models/bolt11_ext.dart';

const kBoltzLiquidLockupTxFeeLowball = 26;
const kBoltzLiquidClaimTxFeeLowball = 14;
// for lowball non-coop, tx is slightly bigger, and the absolute fee is 1 sat higher (if boltz doesn't change the taptree, but there will be other errors if that happens)
// ignore: constant_identifier_names
const kBoltzLiquidClaimTxFeeLowball_NonCoop = 15;
const kBoltzLiquidLockupTxFee = 276;
const kBoltzLiquidClaimTxFee = 152;
const kBoltzReversePercentFee = 0.0025; // 0.25%
const kBoltzSubmarinePercentFee = 0.001; // 0.1%

class BoltzFees {
  //ANCHOR: Submarine
  static int get totalTxFeesSubmarine {
    return kBoltzLiquidLockupTxFeeLowball +
        kBoltzLiquidClaimTxFeeLowball; // assume lowball on our end
  }

  // boltz service fee and boltz claim fee (doesn't include the lockup tx fee which we send)
  static int serviceFeesForAmountSubmarine(int amount) {
    return serviceFeeSubmarine(amount) + kBoltzLiquidClaimTxFeeLowball;
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesSubmarine(BoltzSwapDbModel swapData) {
    final invoiceAmount =
        Bolt11Ext.getAmountFromLightningInvoice(swapData.invoice);
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
    return kBoltzLiquidLockupTxFeeLowball +
        kBoltzLiquidClaimTxFeeLowball; // assume lowball on our end
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesForAmountReverse(int amount) {
    return serviceFeeReverse(amount) + totalTxFeesReverse;
  }

  // lockup tx, claim tx, boltz service fee
  static int totalFeesReverse(BoltzSwapDbModel swapData) {
    final invoiceAmount =
        Bolt11Ext.getAmountFromLightningInvoice(swapData.invoice);
    if (invoiceAmount == null) {
      return 0;
    }

    return totalFeesForAmountReverse(invoiceAmount);
  }

  static int serviceFeeReverse(int amount) {
    return (amount * kBoltzReversePercentFee).ceil();
  }
}
