/// Utility functions for asset-related operations in the send flow
library;

import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';

/// Checks if two assets are different based on their IDs.
///
/// Returns `true` if the parsed asset is non-null and has a different ID
/// from the current asset.
bool isDifferentAsset(Asset asset, Asset? parsedAsset) {
  return parsedAsset != null && parsedAsset.id != asset.id;
}

/// Creates a SwapPair for alt USDT assets.
///
/// Returns a SwapPair from Liquid USDT to the target asset if the asset is
/// an alt USDT type, otherwise returns null.
SwapPair? getSwapPair(Asset asset) {
  return asset.isAltUsdt
      ? SwapPair(
          from: SwapAssetExt.usdtLiquid,
          to: SwapAsset.fromAsset(asset),
        )
      : null;
}

/// Determines the transaction type based on the provided arguments.
///
/// Priority order:
/// 1. If transactionType is explicitly provided, use it
/// 2. If externalPrivateKey is provided, it's a private key sweep
/// 3. Otherwise, it's a regular send
SendTransactionType determineTransactionType(SendAssetArguments args) {
  if (args.transactionType != null) {
    return args.transactionType!;
  }

  if (args.externalPrivateKey != null) {
    return SendTransactionType.privateKeySweep;
  }

  return SendTransactionType.send;
}

/// Determines which asset to use after parsing an address/QR code.
///
/// Logic:
/// - If assets are the same, keep the current asset
/// - If switching from non-LBTC Liquid asset to LBTC, keep the original
///   (to preserve the user's intent to send a specific Liquid asset)
/// - Otherwise, switch to the parsed asset
///
/// Parameters:
/// - [asset]: The current asset
/// - [parsedAsset]: The asset parsed from the address/QR code
/// - [isLiquidButNotLBTC]: Callback to check if an asset is a non-LBTC Liquid asset
/// - [isLBTC]: Callback to check if an asset is LBTC
Asset switchAsset({
  required Asset asset,
  required Asset? parsedAsset,
  required bool Function(Asset) isLiquidButNotLBTC,
  required bool Function(Asset) isLBTC,
}) {
  final isDiffAsset = isDifferentAsset(asset, parsedAsset);

  // Special Case: If the original asset is non-LBTC Liquid asset & the
  // parsed asset is LBTC, keep the original asset.
  final isNonLbtcToLbtc =
      isDiffAsset && isLiquidButNotLBTC(asset) && isLBTC(parsedAsset!);

  return isDiffAsset && !isNonLbtcToLbtc ? parsedAsset! : asset;
}

/// Calculates the parsed amount in satoshis from various input sources.
///
/// Handles different scenarios:
/// - Returns [currentAmount] if [parsedAmount] is null
/// - Returns the amount as-is for Lightning assets (already in sats)
/// - Converts the amount to sats using the [parseAssetAmountToSats] callback for other assets
///
/// The [parseAssetAmountToSats] callback should handle the conversion logic
/// and is typically provided by the formatter service.
int calculateParsedAmount({
  required Decimal? parsedAmount,
  required Asset? parsedAsset,
  required int? currentAmount,
  required int Function(String amount, int precision, Asset? asset)
      parseAssetAmountToSats,
}) {
  if (parsedAmount == null) {
    return currentAmount ?? 0;
  }

  if (parsedAsset?.isLightning ?? false) {
    // Lightning parsed amounts from addresses/invoices are already in sats
    return parsedAmount.toBigInt().toInt();
  }

  return parseAssetAmountToSats(
    parsedAmount.toString(),
    parsedAsset?.precision ?? 0,
    parsedAsset,
  );
}
