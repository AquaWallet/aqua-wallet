import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/features/shared/shared.dart';

final altUsdtValidatorMap = {
  /// Basic Eth validation.
  /// - Checks for 0x prefix
  /// - Checks for 40 hex characters after prefix
  ///
  /// - DOES NOT check checksum
  'eth-usdt': r'^0x[a-fA-F0-9]{40}$',

  /// Basic Tron validation.
  /// - Checks for T prefix
  /// - Checks for 33 characters after prefix
  /// - Checks for valid base58 characters
  ///
  /// - DOES NOT check checksum
  'trx-usdt': r'^T[1-9A-HJ-NP-Za-km-z]{33}$'
};

enum AddressParsingException {
  empty,
  invalid,
  unsupportedInvoice,
  expiredInvoice,
  nonMatchingAssetId
}

class ParsedAddress {
  final String address;
  final double? amount;

  ParsedAddress({required this.address, this.amount});
}

final addressParserProvider = Provider.autoDispose<AddressParser>((ref) {
  return AddressParser(ref);
});

class AddressParser {
  final ProviderRef ref;

  AddressParser(this.ref);

  /// Basic check to see if `address` is valid for a given asset
  Future<bool> isValidAddressForAsset(
      {required Asset asset, required String address}) async {
    if (asset.isBTC) {
      return await ref.read(bitcoinProvider).isValidAddress(address);
    } else if (asset.isLightning) {
      return isLightningInvoice(input: address);
    } else if (asset.isEth) {
      return isUsdtAddress(address);
    } else if (asset.isTrx) {
      return isUsdtAddress(address);
    }

    // If none of the specific asset checks match, try all liquid assets
    return await ref.read(liquidProvider).isValidAddress(address);
  }

  /// Basic check to see if address input is valid for all active assets
  Future<Asset?> isValidAddress({required String address}) async {
    if (await ref.read(bitcoinProvider).isValidAddress(address)) {
      return Asset.btc();
    } else if (isLightningInvoice(input: address) == true) {
      return Asset.lightning();
    } else if (isEthAddress(address) == true) {
      return Asset.usdtEth();
    } else if (isTronAddress(address) == true) {
      return Asset.usdtTrx();
    } else if (await ref.read(liquidProvider).isValidAddress(address)) {
      final uri = Uri.parse(address);
      if (uri.queryParameters['assetid'] != null) {
        return ref.read(manageAssetsProvider).curatedAssets.firstWhere(
              (asset) => asset.id == uri.queryParameters['assetid'],
            );
      } else {
        return ref.read(manageAssetsProvider).lbtcAsset;
      }
    }
    return null;
  }

  /// Parse an `input` for a given `asset` into a `ParsedAddress` (address + amount).
  /// - For lightning, this will return the invoice amount in sats, but also check for a valid invoice or an expired invoice.
  /// - For btc and liquid, this will parse a bip21 address and return the amount in sats. It will also look for matching `assetId` for liquid assets
  ParsedAddress? parseAddress({required Asset asset, required String input}) {
    if (input.isNotEmpty) {
      // lightning
      if (asset.isLightning) {
        try {
          final result = Bolt11PaymentRequest(input);
          final amount = result.amount.toDouble() *
              satsPerBtc; // Bolt11PaymentRequest returns amount in BTC, so convert to sats

          // check expiry
          final expiryTag = result.tags.firstWhere(
            (tag) => tag.type == 'expiry',
            orElse: () => throw AddressParsingException.unsupportedInvoice,
          );
          final expiry = expiryTag.data as int?;
          if (expiry == null) {
            throw AddressParsingException.unsupportedInvoice;
          }
          final timestamp = result.timestamp;
          final DateTime currentTime = DateTime.now();
          final DateTime invoiceExpiryTime =
              DateTime.fromMillisecondsSinceEpoch(
                  (timestamp.toInt() + expiry) * 1000);
          final isExpired = currentTime.isAfter(invoiceExpiryTime);
          if (isExpired) {
            throw AddressParsingException.expiredInvoice;
          }

          return ParsedAddress(address: input, amount: amount);
        } catch (e) {
          if (e is AddressParsingException) {
            rethrow;
          } else {
            throw AddressParsingException.unsupportedInvoice;
          }
        }
      }
    }

    // btc & all liquid assets
    final decoder = Bip21Decoder(input);

    // check if matching asset
    if (decoder.assetId != null &&
        decoder.assetId!.isNotEmpty &&
        asset.id != decoder.assetId) {
      throw AddressParsingException.nonMatchingAssetId;
    }

    return ParsedAddress(address: decoder.address, amount: decoder.amount);
  }

  /// Basic check if lightning invoice
  bool isLightningInvoice({required String input}) {
    try {
      final _ = Bolt11PaymentRequest(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Basic check for layer two address (currently lighting or liquid)
  Future<bool> isLayerTwoAddress(String address) async {
    return isLightningInvoice(input: address) ||
        await ref.read(liquidProvider).isValidAddress(address);
  }

  /// Basic check if this is eth or tron address
  bool isAltUsdtAddress({required String input}) {
    for (final regex in altUsdtValidatorMap.values) {
      if (RegExp(regex).hasMatch(input)) {
        return true;
      }
    }

    return false;
  }

  /// Basic check if this is a liquid, eth, or tron address
  Future<bool> isUsdtAddress(String address) async {
    return await ref.read(liquidProvider).isValidAddress(address) ||
        isAltUsdtAddress(input: address);
  }

  /// Basic specific check for eth address
  bool isEthAddress(String address) {
    return RegExp(altUsdtValidatorMap['eth-usdt']!).hasMatch(address);
  }

  /// Basic specific check for tron address
  bool isTronAddress(String address) {
    return RegExp(altUsdtValidatorMap['trx-usdt']!).hasMatch(address);
  }
}
