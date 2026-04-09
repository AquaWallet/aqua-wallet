import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/elements.dart';
import 'package:aqua/features/address_validator/utils/base58_address_validator.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/features/wallet/utils/mini_private_key_service.dart';
import 'package:aqua/logger.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:boltz/boltz.dart';
import 'package:decimal/decimal.dart';

import 'models/address_validator_models.dart';
import 'moneybadger_decode_provider.dart';

final altUsdtValidatorMap = {
  /// Basic Eth validation.
  /// - Checks for 0x prefix
  /// - Checks for 40 hex characters after prefix
  Asset.usdtEth().id: r'^0x[a-fA-F0-9]{40}$',

  /// Basic Tron validation.
  /// - Checks for T prefix
  /// - Checks for 33 characters after prefix
  /// - Checks for valid base58 characters
  Asset.usdtTrx().id: r'^T[1-9A-HJ-NP-Za-km-z]{33}$',

  /// Basic Binance Smart Chain validation (similar to Ethereum).
  /// - Checks for 0x prefix
  /// - Checks for 40 hex characters after prefix
  Asset.usdtBep().id: r'^0x[a-fA-F0-9]{40}$',

  /// Basic Solana validation.
  /// - Checks for 32-44 characters
  /// - Checks for valid base58 characters
  Asset.usdtSol().id: r'^[1-9A-HJ-NP-Za-km-z]{32,44}$',

  /// Basic Polygon validation (similar to Ethereum).
  /// - Checks for 0x prefix
  /// - Checks for 40 hex characters after prefix
  Asset.usdtPol().id: r'^0x[a-fA-F0-9]{40}$',

  /// Basic TON validation.
  /// - User-friendly format: EQ/UQ prefix followed by 46 base64/base64url chars
  ///   Base64 allows A-Z, a-z, 0-9, + and /
  ///   Base64url allows A-Z, a-z, 0-9, - and _
  ///
  /// Bounceable vs Non-bounceable:
  /// - EQ prefix (bounceable): Used for smart contracts. If the transaction fails,
  ///   funds are automatically returned to the sender minus network fees.
  /// - UQ prefix (non-bounceable): Used for simple wallets. If the transaction fails,
  ///   funds are NOT returned to protect against replay attacks.
  ///
  /// - Raw format: workchain_id (0 or -1) followed by : and 64 hex chars
  ///   where 0 is basechain and -1 is masterchain
  ///
  /// See TON docs: https://docs.ton.org/v3/documentation/smart-contracts/addresses
  Asset.usdtTon().id:
      r'^(?:(?:EQ|UQ)[A-Za-z0-9+/_-]{46}|(?:0|-1):[0-9a-fA-F]{64})$',
};

final addressParserProvider = Provider.autoDispose<AddressParser>((ref) {
  return AddressParser(ref);
});

class AddressParser {
  final ProviderRef ref;

  AddressParser(this.ref);

  /// Basic check to see if `address` is valid for a given asset
  ///
  /// - [accountForCompatibleAssets] will return true if this address is valid for a compatible asset,
  ///  for example, if the address is a lightning invoice, but the asset is LBTC, this will return true
  ///
  ///  checks if address is valid for specific asset
  Future<bool> isValidAddressForAsset(
      {required Asset asset,
      required String address,
      bool accountForCompatibleAssets = false}) async {
    // check with compatible assets
    if (accountForCompatibleAssets && asset.hasCompatibleAssets) {
      if (asset.isLayerTwo) {
        final valid = isLightning(address) ||
            await ref.read(liquidProvider).isValidAddress(address);
        return valid;
      } else if (asset.isAnyUsdt) {
        return isUsdtAddress(address);
      }
    }

    // check only for specific asset
    if (asset.isBTC) {
      return await ref.read(bitcoinProvider).isValidAddress(address);
    } else if (asset.isLightning) {
      return isLightning(address);
    } else if (asset.isEth) {
      return isEthAddress(address);
    } else if (asset.isTrx) {
      return isTronAddress(address);
    } else if (asset.isBep) {
      return isBepAddress(address);
    } else if (asset.isSol) {
      return isSolAddress(address);
    } else if (asset.isPol) {
      return isPolAddress(address);
    } else if (asset.isTon) {
      return isTonAddress(address);
    }

    // If none of the specific asset checks match, try all liquid assets
    return await ref.read(liquidProvider).isValidAddress(address);
  }

  /// Attempt to parse an Asset from an input
  Future<List<Asset>> parseAsset(
      {required String address, Asset? asset}) async {
    if (await ref.read(bitcoinProvider).isValidAddress(address)) {
      return [Asset.btc()];
    } else if (isLightning(address)) {
      return [Asset.lightning()];
    }

    final usdtAsset = _parseAltUsdtAsset(address, asset);
    if (usdtAsset.isNotEmpty) {
      return usdtAsset;
    }

    if (await ref.read(liquidProvider).isValidAddress(address)) {
      final uri = Uri.parse(address);
      if (uri.queryParameters['assetid'] != null) {
        final asset = ref.read(manageAssetsProvider).curatedAssets.firstWhere(
              (asset) => asset.id == uri.queryParameters['assetid'],
              orElse: () => throw AddressParsingException(
                  AddressParsingExceptionType.assetNotInManagedAssets),
            );
        return [asset];
      } else {
        return [ref.read(manageAssetsProvider).lbtcAsset];
      }
    } // We only call moneybadger/decode if we didn't find a matching asset
    final parsed = await _decodeMoneybadger(address);
    if (parsed != null) return [Asset.lightning()];
    return [];
  }

  Future<ParsedAddress?> _decodeMoneybadger(String input) async {
    final decoded =
        await ref.read(moneybadgerDecodeProvider.notifier).decode(input);
    if (decoded != null && decoded.isNotEmpty) {
      return await _parseLightningAddress(decoded);
    }
    return null;
  }

  /// Parse an `input` into a `ParsedAddress` (address + amount).
  /// - For lightning, this will return the invoice amount in sats, but also check for a valid invoice, expired invoice, or no amount in invoice.
  /// - For btc and liquid, this will parse a bip21 address and return the amount in sats. It will also look for matching `assetId` for liquid assets
  Future<ParsedAddress?> parseInput(
      {Asset? asset,
      required String input,
      bool accountForCompatibleAssets = true}) async {
    if (input.isEmpty) {
      throw AddressParsingException(AddressParsingExceptionType.emptyAddress);
    }

    // replace asset with parsed asset if compatible, otherwise if asset is null set as parsedAsset
    final parsedAssets = await parseAsset(address: input, asset: asset);

    final switchedAsset = _switchedAsset(
        asset, parsedAssets.firstOrNull, accountForCompatibleAssets);
    if (switchedAsset != null) {
      asset = switchedAsset;
    }

    if (asset == null) {
      throw AddressParsingException(AddressParsingExceptionType.invalidAddress);
    }

    try {
      // Compressed private key
      final miniPrivateKeyService = MiniPrivateKeyService();
      if (miniPrivateKeyService.isValidMiniPrivateKey(input)) {
        final wifPrivateKey = miniPrivateKeyService.miniKeyToWIF(input);
        logger.debug('Valid wif private key: $wifPrivateKey');
        return ParsedAddress(
            address: '',
            extPrivateKey: wifPrivateKey,
            ambiguousAssets: parsedAssets,
            asset:
                asset); // leave send address empty for now, will be set in send flow
      }

      // Unified bip21 (lightning first)
      final parsedBip21 =
          await parseBIP21(input, asset, accountForCompatibleAssets);
      if (parsedBip21 != null) {
        return parsedBip21;
      }

      // verify if layer2 and try to parse lightning invoice or lightning address if layerTwo
      if (asset.isLayerTwo) {
        // If asset is layer two then parsedAssets will either have one asset or be empty
        final detectedAsset = parsedAssets.firstOrNull;
        if (detectedAsset != null && !detectedAsset.isLayerTwo) {
          throw AddressParsingException(
              AddressParsingExceptionType.nonMatchingAssetId);
        }

        if (isValidLightningAddressFormat(input)) {
          return await _parseLightningAddress(input);
        }

        if (isValidLNURL(input)) {
          return await _parseLNURL(input);
        }

        final parsed = await _decodeMoneybadger(input);
        if (parsed != null) return parsed;

        if (isLightningInvoice(input: input)) {
          final submarineFees = await ref
              .read(boltzFeesProvider.future)
              .then((value) => value.submarine());
          return await _parseLightningInvoice(input, asset, submarineFees);
        }
      }

      // check all other addresses
      if (await isValidAddressForAsset(
          asset: asset,
          address: input,
          accountForCompatibleAssets: accountForCompatibleAssets)) {
        logger.debug(
            '[AddressParser] valid address: $input - asset: ${asset.name} - assetId: ${asset.id}');
        return ParsedAddress(
            address: input,
            asset: asset,
            assetId: asset.id,
            ambiguousAssets: parsedAssets);
      } else {
        // throw if not valid address for asset
        if (parsedAssets.isNotEmpty) {
          throw AddressParsingException(
              AddressParsingExceptionType.nonMatchingAssetId);
        } else {
          throw AddressParsingException(
              AddressParsingExceptionType.invalidAddress);
        }
      }
    } on AddressParsingException {
      rethrow;
    } catch (e) {
      throw AddressParsingException(AddressParsingExceptionType.invalidAddress);
    }
  }

  /// Returns the `parsedAsset` if we should switch from the original asset.
  /// For instance, if the user is on a LBTC send flow, but scans a BTC bip21 with a lightning invoice, switch to lightning asset
  /// Or if user is on USDt-trx flow, but scans a plain Liquid address, switch to USDt-Liquid
  Asset? _switchedAsset(Asset? originalAsset, Asset? parsedAsset,
      bool accountForCompatibleAssets) {
    if (originalAsset == null) {
      return parsedAsset;
    } else if (parsedAsset != null) {
      if (originalAsset.isAltUsdt && parsedAsset.isLiquid) {
        return ref.read(manageAssetsProvider).liquidUsdtAsset;
      } else if (accountForCompatibleAssets &&
          originalAsset.isCompatibleWith(parsedAsset)) {
        return parsedAsset;
      }
    }
    return null;
  }

  /// Parse Lightning Address
  Future<ParsedAddress?> _parseLightningAddress(String input) async {
    try {
      final lnurlp = ref.read(lnurlProvider).convertLnAddressToWellKnown(input);
      if (lnurlp == null) {
        return null;
      }

      // this calls the `.well-known/lnurlp` endpoint to get the params - will return an error if no a valid lightning address server
      final result = await getParamsFromLnurlServer(Uri.parse(lnurlp));
      logger.debug(
          "[LNURL] lightning address params: ${result.payParams?.callback} - ${result.payParams?.minSendable}");
      if (result.error != null) {
        throw Exception("Not a valid lightning address");
      }

      // If it's a fixed amount LNURL-pay, set the amount in sats
      final amount = result.isLnurlPayFixedAmount
          ? result.payParams!.minSendableSats
          : null;

      final parsedLightningAddress = ParsedAddress(
        address: input,
        asset: Asset.lightning(),
        lnurlParseResult: result,
        amountInSats: amount,
      );

      return parsedLightningAddress;
    } catch (e) {
      throw AddressParsingException(
          AddressParsingExceptionType.invalidLightningAddress);
    }
  }

  /// Parse LNURL
  Future<ParsedAddress?> _parseLNURL(String input) async {
    try {
      final decoded = decodeLnurlUri(input);
      logger.debug("[LNURL] lnurl decoded: $decoded");
      final result = await getParamsFromLnurlServer(decoded);
      final lnurlWithdrawEnabled =
          ref.read(featureFlagsProvider.select((p) => p.lnurlWithdrawEnabled));

      // lnurlWithdrawFeatureFlag check
      if (result.withdrawalParams != null && !lnurlWithdrawEnabled) {
        throw AddressParsingException(AddressParsingExceptionType.generic,
            customMessage: "LNURL Withdraw not yet supported");
      }

      if (result.error != null) {
        throw AddressParsingException(AddressParsingExceptionType.generic,
            customMessage: result.error!.reason);
      }

      final fixedAmount = result.isLnurlPayFixedAmount
          ? result.payParams!.minSendableSats
          : null;
      return ParsedAddress(
        amountInSats: fixedAmount,
        address: input,
        asset: Asset.lightning(),
        lnurlParseResult: result,
      );
    }
    // rethrow AddressParsingException, any other exception just return null
    on AddressParsingException catch (_) {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  /// Parse Lightning Invoice
  Future<ParsedAddress?> _parseLightningInvoice(
      String input, Asset asset, SubmarineFeesAndLimits submarineFees) async {
    try {
      String processedInput = input.toLowerCase();
      if (processedInput.startsWith('lightning:')) {
        processedInput = processedInput.substring('lightning:'.length);
      }
      final result = Bolt11PaymentRequest(processedInput);

      // Check for routing hints in LN invoice (this is a minor hack to fix an issue with Aqua > Aqua swaps)
      final parsedBoltzRoutingHint =
          await _parseBoltzRoutingHint(processedInput, result);
      if (parsedBoltzRoutingHint != null) {
        return parsedBoltzRoutingHint;
      }

      // check amount (for now we are not supporting invoices without an amount)
      final amount = (result.amount *
          Decimal.fromInt(
              satsPerBtc)); // Bolt11PaymentRequest returns amount in BTC, so convert to sats

      if (amount == Decimal.zero) {
        throw AddressParsingException(
            AddressParsingExceptionType.noAmountInInvoice);
      }

      // validate minimum and maximum amounts
      final minSats = SendAssetAmountConstraints.lightning(
        submarineFees: submarineFees,
      ).minSats;
      if (amount < Decimal.fromInt(minSats)) {
        final formatter = ref.read(formatProvider);
        final unitsProvider = ref.read(displayUnitsProvider);
        final currentUnit = unitsProvider.currentDisplayUnit;
        final minAmountFormatted = formatter.formatAssetAmount(
          amount: minSats,
          asset: Asset.btc(),
          displayUnitOverride: currentUnit,
        );

        final displayUnitTicker =
            unitsProvider.getAssetDisplayUnit(Asset.lightning());

        throw AddressParsingException(
          AddressParsingExceptionType.lessThanMinAmountInInvoice,
          amount: minAmountFormatted,
          unit: displayUnitTicker,
        );
      }

      if (amount >
          Decimal.fromInt(
              SendAssetAmountConstraints.lightning(submarineFees: submarineFees)
                  .maxSats)) {
        throw AddressParsingException(
            AddressParsingExceptionType.greaterThanMaxAmountInInvoice);
      }

      // check expiry
      final expiryTag = result.tags.firstWhereOrNull(
        (tag) => tag.type == 'expiry',
      );
      final expiry =
          expiryTag?.data as int? ?? 3600; // Default expiry is 3600 by BOLT-11
      final timestamp = result.timestamp;
      final DateTime currentTime = DateTime.now();
      final DateTime invoiceExpiryTime = DateTime.fromMillisecondsSinceEpoch(
          (timestamp.toInt() + expiry) * 1000);
      final isExpired = currentTime.isAfter(invoiceExpiryTime);
      if (isExpired) {
        throw AddressParsingException(
            AddressParsingExceptionType.expiredInvoice);
      }

      return ParsedAddress(
          address: processedInput,
          amountInSats: amount.toBigInt().toInt(),
          asset: Asset.lightning()); // change asset to lightning
    } on AddressParsingException {
      rethrow;
    } catch (e) {
      // if lightning and something went wrong, this is an invalid invoice
      if (asset.isLightning) {
        throw AddressParsingException(
            AddressParsingExceptionType.invalidAddress);
      } else {
        // do nothing, continue to parse below since this could be another layerTwo address
        return null;
      }
    }
  }

  /// Parse Bip21
  Future<ParsedAddress?> parseBIP21(
      String input, Asset asset, bool accountForCompatibleAssets) async {
    try {
      final decoder = Bip21Decoder(input);

      if (decoder.assetId != null && decoder.assetId != asset.id) {
        throw AddressParsingException(
            AddressParsingExceptionType.nonMatchingAssetId);
      }

      // throw if not valid address for asset
      final inputToValidate = asset.isLightning || asset.isLBTC
          ? decoder.lightning
          : decoder.address;
      if (await isValidAddressForAsset(
              asset: asset,
              address: inputToValidate ?? decoder.address,
              accountForCompatibleAssets: accountForCompatibleAssets) ==
          false) {
        throw AddressParsingException(
            AddressParsingExceptionType.nonMatchingAssetId);
      }

      // if a lightning invoice, try to parse it
      ParsedAddress? parsedLNInvoice;
      final lbtcBalance = await ref.read(balanceProvider).getLBTCBalance();
      if (decoder.lightning != null && lbtcBalance > 0) {
        try {
          final submarineFees = await ref
              .read(boltzFeesProvider.future)
              .then((value) => value.submarine());
          parsedLNInvoice = await _parseLightningInvoice(
              decoder.lightning!, asset, submarineFees);
        } catch (e, _) {
          // if lightning invoice was included but something went wrong such as an expired invoice, don't rethrow as we want to fallback to btc
        }
      }

      final parseAsLightning = parsedLNInvoice != null && lbtcBalance > 0;
      final parsedAsset = parseAsLightning ? Asset.lightning() : asset;
      final amountInSats = decoder.amount != null
          ? decodeBip21AmountToSats(
              bip21Amount: decoder.amount!, asset: parsedAsset)
          : null;
      final parsedAddress = parsedLNInvoice ??
          ParsedAddress(
              address: decoder.address,
              amountInSats: amountInSats,
              asset: parsedAsset,
              assetId: decoder.assetId,
              message: decoder.message,
              label: decoder.label,
              lightningInvoice: decoder.lightning);
      return parsedAddress;
    } on AddressParsingExceptionType catch (_) {
      rethrow;
    } catch (e) {
      if (e is AddressParsingException &&
          e.type == AddressParsingExceptionType.nonMatchingAssetId) {
        rethrow;
      }
      return null;
    }
  }

  /// This is a minor hack to fix an issue with Aqua > Aqua swaps.
  /// If this LN Invoice was created in Aqua through a Boltz Reverse Swap,
  /// it will have a routing hint with info on how to fetch a bip21 with a liquid address to pay directly.
  Future<ParsedAddress?> _parseBoltzRoutingHint(
      String invoice, Bolt11PaymentRequest bolt11) async {
    try {
      final routingTag =
          bolt11.tags.firstWhereOrNull((tag) => tag.type == 'routing');
      List<dynamic>? routingData = routingTag?.data;
      if (routingData != null && routingData[0] is Map) {
        // get pubkey from routing hint (this is the pubkey we sent when creating reverse swap)
        // note: pubkey is a standard field in routingHints, so other non-boltz invoices can have them
        Map routingInfo = routingData[0];
        final shortChannelId = routingInfo["short_channel_id"];
        if (shortChannelId != "0846c900051c0000") {
          return null;
        }

        final pubkey = routingInfo["pubkey"];
        if (pubkey == null) {
          return null;
        }

        // fetch the bip21 from boltz using ln invoice for address and sig
        final reverseSwapBip21AsyncValue =
            await ref.read(fetchReverseSwapBip21Provider(invoice).future);
        final signature = reverseSwapBip21AsyncValue.signature;
        final bip21 = reverseSwapBip21AsyncValue.bip21;
        final lbtcAsset = ref.read(manageAssetsProvider).lbtcAsset;
        final parseBip21 = await parseBIP21(bip21, lbtcAsset, false);
        if (parseBip21 == null || parseBip21.amountInSats == null) {
          return null;
        }

        final isVerified = Elements.verifySignatureSchnorr(
            signature, parseBip21.address, pubkey);

        if (!isVerified) {
          throw AddressParsingException(
              AddressParsingExceptionType.boltzInvoiceError);
        }

        logger.debug(
            "[Boltz] routing hint - invoice amount: ${bolt11.amount} - bip21 amount: ${parseBip21.amountInSats}");

        return parseBip21.copyWith(
            isBoltzToBoltzSwap: true,
            amountInSats: (bolt11.amount * Decimal.fromInt(satsPerBtc))
                .toBigInt()
                .toInt()); // set the amount to the amount in the invoice without boltz fees
      }
      return null;
    } on AddressParsingException catch (e) {
      if (e.type == AddressParsingExceptionType.boltzInvoiceError) {
        rethrow;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  /// Parse the pubkey from a Bolt11PaymentRequest
  String? parseBoltzRoutingHintPubkey(String invoice) {
    try {
      String processedInput = invoice.toLowerCase();
      if (processedInput.startsWith('lightning:')) {
        processedInput = processedInput.substring('lightning:'.length);
      }
      final result = Bolt11PaymentRequest(processedInput);
      final routingTag =
          result.tags.firstWhereOrNull((tag) => tag.type == 'routing');
      List<dynamic>? routingData = routingTag?.data;
      if (routingData != null && routingData[0] is Map) {
        // get pubkey from routing hint (this is the pubkey we sent when creating reverse swap)
        // note: pubkey is a standard field in routingHints, so other non-boltz invoices can have them
        Map routingInfo = routingData[0];
        final pubkey = routingInfo["pubkey"];
        return pubkey;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Convenience checks for AddressParser
extension AddressParserExt on AddressParser {
  /// Overall check for any of the valid lightning formats
  bool isLightning(String input) {
    return isBip21WithInvoice(input: input) ||
        isLightningInvoice(input: input) ||
        isValidLightningAddressFormat(input) ||
        isValidLNURL(input);
  }

  /// Initial check is valid standard lightning address format. However, since a lightning address `user@jan3.com` is really just in an email format,
  ///   this is just checks that initial format.
  /// The real test of a lightning address is to try to convert it to a well-known lnurlp address, in `convertLnAddressToWellKnown` and make a request to it.
  bool isValidLightningAddressFormat(String input) {
    return ref.read(lnurlProvider).isValidLightningAddressFormat(input);
  }

  /// Check is valid LNURL
  bool isValidLNURL(String input) {
    return ref.read(lnurlProvider).isValidLnurl(input);
  }

  /// Basic check if lightning invoice
  bool isLightningInvoice({required String input}) {
    try {
      String processedInput = input.toLowerCase();
      if (processedInput.startsWith('lightning:')) {
        processedInput = processedInput.substring('lightning:'.length);
      }

      final _ = Bolt11PaymentRequest(processedInput);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if bip21 with invoice
  bool isBip21WithInvoice({required String input}) {
    try {
      String processedInput = input.toLowerCase();
      if (processedInput.startsWith('lightning:')) {
        processedInput = processedInput.substring('lightning:'.length);
      }

      final decoder = Bip21Decoder(processedInput);
      return decoder.lightning != null;
    } catch (e) {
      return false;
    }
  }

  /// Basic check for layer two address (currently lighting or liquid)
  Future<bool> isLayerTwoAddress(String address) async {
    return isLightningInvoice(input: address) ||
        await ref.read(liquidProvider).isValidAddress(address);
  }

  //ANCHOR - USDT Addresses
  List<Asset> _parseAltUsdtAsset(String address, Asset? asset) {
    final activeUsdts = ref.read(activeAltUSDtsProvider);

    // Special case: Ethereum, Binance, and Polygon share the same address format (0x...)
    // Return all compatible assets so user can select the network
    if (isEthAddress(address)) {
      final validAssets = [Asset.usdtEth(), Asset.usdtBep(), Asset.usdtPol()];
      return validAssets.where((asset) => activeUsdts.contains(asset)).toList();
    }

    // If a specific asset is provided, check if address matches that asset
    if (asset != null && asset.isAltUsdt) {
      if ((asset.isTrx && isTronAddress(address)) ||
          (asset.isSol && isSolAddress(address)) ||
          (asset.isEth && isEthAddress(address)) ||
          (asset.isBep && isBepAddress(address)) ||
          (asset.isPol && isPolAddress(address)) ||
          (asset.isTon && isTonAddress(address))) {
        return [asset];
      }
    }

    // Auto-detect chain when no specific asset is provided
    if (isTronAddress(address) && activeUsdts.contains(Asset.usdtTrx())) {
      return [Asset.usdtTrx()];
    }
    if (isSolAddress(address) && activeUsdts.contains(Asset.usdtSol())) {
      return [Asset.usdtSol()];
    }
    if (isTonAddress(address) && activeUsdts.contains(Asset.usdtTon())) {
      return [Asset.usdtTon()];
    }

    return [];
  }

  /// Basic check if this is a liquid, eth, tron, bep, sol, pol, or ton address
  Future<bool> isUsdtAddress(String address) async {
    return await ref.read(liquidProvider).isValidAddress(address) ||
        isAltUsdtAddress(input: address);
  }

  /// Basic check if this is an alt usdt address
  bool isAltUsdtAddress({required String input}) {
    final activeUsdts = ref.read(activeAltUSDtsProvider);
    return (isEthAddress(input) && activeUsdts.contains(Asset.usdtEth())) ||
        (isTronAddress(input) && activeUsdts.contains(Asset.usdtTrx())) ||
        (isBepAddress(input) && activeUsdts.contains(Asset.usdtBep())) ||
        (isSolAddress(input) && activeUsdts.contains(Asset.usdtSol())) ||
        (isPolAddress(input) && activeUsdts.contains(Asset.usdtPol())) ||
        (isTonAddress(input) && activeUsdts.contains(Asset.usdtTon()));
  }

  /// Basic check for eth address
  bool isEthAddress(String address) {
    return RegExp(altUsdtValidatorMap[Asset.usdtEth().id]!).hasMatch(address);
  }

  /// Basic check for tron address
  /// Uses regex for fast pre-check, then Base58Check validation for accuracy
  bool isTronAddress(String address) {
    // Fast regex pre-check
    if (!RegExp(altUsdtValidatorMap[Asset.usdtTrx().id]!).hasMatch(address)) {
      return false;
    }
    // Accurate Base58Check validation with checksum verification
    return isValidTronAddressWithChecksum(address);
  }

  /// Basic check for Binance Smart Chain address
  bool isBepAddress(String address) {
    return RegExp(altUsdtValidatorMap[Asset.usdtBep().id]!).hasMatch(address);
  }

  /// Basic check for Solana address
  /// Uses regex for fast pre-check, then Base58 decode validation for accuracy
  bool isSolAddress(String address) {
    // Fast regex pre-check
    if (!RegExp(altUsdtValidatorMap[Asset.usdtSol().id]!).hasMatch(address)) {
      return false;
    }
    // Accurate Base58 decode validation (must decode to exactly 32 bytes)
    return isValidSolanaAddressWithDecode(address);
  }

  /// Basic check for Polygon address
  bool isPolAddress(String address) {
    return RegExp(altUsdtValidatorMap[Asset.usdtPol().id]!).hasMatch(address);
  }

  /// Basic check for TON address
  bool isTonAddress(String address) {
    return RegExp(altUsdtValidatorMap[Asset.usdtTon().id]!).hasMatch(address);
  }
}
