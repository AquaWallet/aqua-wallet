import 'dart:async';
import 'dart:convert';
import 'package:aqua/common/decimal/decimal_ext.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/address_validator/address_validation.dart';
import 'package:aqua/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:aqua/features/send/providers/send_asset_transaction_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/utils/utils.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:aqua/common/crypto/generate_random_bytes.dart';
import 'package:aqua/common/crypto/secp256k1_key_pair.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:pointycastle/export.dart';
import 'package:aqua/elements.dart';
import 'package:aqua/features/settings/manage_assets/providers/manage_assets_provider.dart';
import 'boltz.dart';

const boltzReferralId = 'AQUA';
const boltzMin = 1000;
const boltzMax = 25000000;
const boltzMinString = "1,000";
const boltzMaxString = "25,000,000";
const boltzClaimTxFeeBudget = 152; // hardcode to 152 for now

final boltzProvider = Provider<BoltzService>((ref) {
  return BoltzService(ref);
});

/////////////////////////////////////////
// Normal swap providers ////////////////;

// cache initial call response - normal
final boltzSwapSuccessResponseProvider =
    StateProvider.autoDispose<BoltzCreateSwapResponse?>((ref) => null);

/////////////////////////////////////////
// Reverse swap providers ///////////////

// cache initial call response - reverse
final boltzReverseSwapSuccessResponseProvider =
    StateProvider.autoDispose<BoltzCreateReverseSwapResponse?>((ref) => null);

// cache mempooltx from swapstatus update
// - this is also the point at which the claim tx can be broadcasted

final boltzReverseSwapMempoolTxProvider =
    StateProvider.family.autoDispose<String?, String>((ref, id) => null);

/////////////////////////////////////////
// Swap status provider /////////////////
class SwapStatusRequest {
  final String id;
  final bool forceNewStream;

  SwapStatusRequest({required this.id, this.forceNewStream = false});
}

final boltzSwapStatusStreamProvider =
    StreamProvider.family<BoltzSwapStatusResponse, SwapStatusRequest>(
        (ref, request) {
  return ref
      .read(boltzProvider)
      .getSwapStatusStream(request.id, forceNewStream: request.forceNewStream);
});

/// Fetches a boltz swap by the onchain tx hash
final boltzSwapFromTxHashProvider = FutureProvider.autoDispose
    .family<BoltzSwapData?, String>((ref, txhash) async {
  if (txhash.isEmpty) {
    return null;
  }

  return await ref
      .read(boltzDataProvider)
      .getBoltzNormalSwapDataByOnchainTx(txhash);
});

final boltzReverseSwapFromTxHashProvider = FutureProvider.autoDispose
    .family<BoltzReverseSwapData?, String>((ref, txhash) async {
  if (txhash.isEmpty) {
    return null;
  }

  return await ref
      .read(boltzDataProvider)
      .getBoltzReverseSwapDataByOnchainTx(txhash);
});

/// Forms refund data for a normal swap
final boltzSwapRefundDataProvider = Provider.autoDispose
    .family<BoltzRefundData?, BoltzSwapData>((ref, boltzSwapData) {
  return BoltzRefundData(
      id: boltzSwapData.response.id,
      privateKey: boltzSwapData.secureData.privateKeyHex,
      blindingKey: boltzSwapData.response.blindingKey,
      redeemScript: boltzSwapData.response.redeemScript,
      timeoutBlockHeight: boltzSwapData.response.timeoutBlockHeight);
});

////////////////////////////////////////
// Get pairs provider //////////////////
final boltzGetPairsProvider =
    FutureProvider<BoltzGetPairsResponse>((ref) async {
  if (ref.read(boltzGetPairsStateProvider.notifier).state != null) {
    return Future.value(ref.read(boltzGetPairsStateProvider.notifier).state);
  }
  return await ref.read(boltzProvider).getPairs();
});

final boltzGetPairsStateProvider =
    StateProvider<BoltzGetPairsResponse?>((ref) => null);

/////////////////////////////////////////
// Error provider ///////////////////////
final boltzErrorResponseProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/////////////////////////////////////////
// Main boltz provider //////////////////
class BoltzService {
  final ProviderRef ref;

  BoltzService(this.ref);

  /// Map streams controllers to assure we don't open multiple identical streams
  final Map<String, StreamController<BoltzSwapStatusResponse>>
      _statusStreamControllers = {};

  // ANCHOR: - Create Swap

  /// Create Onchain to Lightning swap
  Future<BoltzCreateSwapResponse> createSwap({
    required String invoice,
    BuildContext? context,
  }) async {
    // check if swap with that invoice already exists
    final existingSwap = await ref
        .read(boltzDataProvider)
        .getBoltzNormalSwapDataByInvoice(invoice);

    if (existingSwap != null) {
      ref.read(boltzSwapSuccessResponseProvider.notifier).state =
          existingSwap.response;
      return existingSwap.response;
    }

    // if not, create new sawp
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}createswap';

    final client = ref.read(dioProvider);
    logger.i("[BOLTZ] using boltz service uri: $uri");

    // Key pair generation using secp256k1
    final keyPair = secp256k1KeyPair();
    final privateKeyHex = privateKeyToHex(keyPair.privateKey as ECPrivateKey);
    final publicKeyHex = publicKeyToHex(keyPair.publicKey as ECPublicKey);

    // Secure storage
    final swapSecureData = BoltzSwapSecureData(privateKeyHex: privateKeyHex);

    // Request
    final request = BoltzCreateSwapRequest(
      type: SwapType.submarine,
      pairId: PairId.lbtcBtc,
      orderSide: OrderSide.sell,
      invoice: invoice,
      refundPublicKey: publicKeyHex,
      referralId: 'AQUA',
    );

    logger.d("[BOLTZ] boltz swap request: ${request.toJson()}");

    // Response
    try {
      final apiResponse = await client.post(uri, data: request.toJson());

      final json = apiResponse.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz swap response: $json");
      final swapResponse = BoltzCreateSwapResponse.fromJson(json);

      // cache response
      ref.read(boltzSwapSuccessResponseProvider.notifier).state = swapResponse;

      // Add to swap checker streamer
      ref
          .read(boltzStatusCheckProvider)
          .streamSingleSwapStatus(swapResponse.id);

      // validate returned redeem script and address againt preimage
      final bolt11Result = Bolt11PaymentRequest(invoice);
      final preimageHash = bolt11Result.tags
          .firstWhere(
            (tag) => tag.type == 'payment_hash',
            orElse: () => throw Exception(
                '[BOLTZ] Redeem script from response cannot parse payment_hash'),
          )
          .data
          .toString();

      final redeemScriptFromBoltz = swapResponse.redeemScript;
      final claimPublicKeyFromBoltz =
          Elements.extractPublicKeyFromRedeemScript(redeemScriptFromBoltz);

      final validateSubmarine = Elements.validateSubmarine(
          preimageHash,
          claimPublicKeyFromBoltz,
          publicKeyHex,
          swapResponse.timeoutBlockHeight,
          swapResponse.address,
          redeemScriptFromBoltz,
          swapResponse.blindingKey);

      if (!validateSubmarine && context != null && context.mounted) {
        ref.read(boltzErrorResponseProvider.notifier).state =
            context.loc.boltzRedeemScriptValidationError;
        throw AsyncValue.error(
            context.loc.boltzRedeemScriptValidationError, StackTrace.empty);
      }

      // Store preimage, private key, and response in secure storage until the swap is resolved
      final getPairsResponse = await getPairs();
      final boltzSwapData = BoltzSwapData(
          created: DateTime.now(),
          request: request,
          response: swapResponse,
          fees: getPairsResponse,
          secureData: swapSecureData);
      await ref
          .read(boltzDataProvider)
          .saveBoltzNormalSwapData(boltzSwapData, swapResponse.id);

      // Send onchain swap payment
      return swapResponse;
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz swap error: ${e.response?.statusCode}, ${e.response?.data}");
      ref.read(boltzErrorResponseProvider.notifier).state =
          e.response?.data.toString();
      return Future.error(e.response?.data);
    }
  }

  // ANCHOR: - Create Reverse Swap

  /// Lightning to Onchain swap
  Future<BoltzCreateReverseSwapResponse> createReverseSwap(
      int invoiceAmount) async {
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}createswap';

    final client = ref.read(dioProvider);
    logger.i("[BOLTZ] using boltz service uri: $uri");

    // Preimage generation
    final sha256 = SHA256Digest();
    final preimage = generateRandom32Bytes();
    final preimageHex = hex.encode(preimage);
    final preimageHash = sha256.process(preimage);
    final preimageHashHex = hex.encode(preimageHash);
    final (privateKeyHex, publicKeyHex) = Elements.getKeyPair();

    // Secure storage
    final swapSecureData = BoltzSwapSecureData(
        privateKeyHex: privateKeyHex, preimageHex: preimageHex);
    logger.d('[BOLTZ] public key: ${publicKeyHex.length} - $publicKeyHex');
    logger.d('[BOLTZ] preimageHashHex: $preimageHashHex');

    BoltzCreateReverseSwapRequest request;

    // Create fallback address (this is a hack to fix an issue where if the send/receive is from aqua to aqua, boltz will add this to the ln invoice, and
    // if that invoice is scanned by another user then aqua should look for this fallback address and pay to liquid onchain directly, bypassing the boltz swap)
    final address = await ref.read(liquidProvider).getReceiveAddress();
    if (address == null || address.address == null) {
      throw Exception(
          'Receive address is null when trying to construct claim tx');
    }
    final addressSig =
        Elements.signMessageSchnorr(address.address!, privateKeyHex);

    // Request
    request = BoltzCreateReverseSwapRequest(
        type: SwapType.reversesubmarine,
        pairId: PairId.lbtcBtc,
        orderSide: OrderSide.buy,
        invoiceAmount: invoiceAmount,
        claimPublicKey: publicKeyHex,
        preimageHash: preimageHashHex,
        address: address.address!,
        addressSignature: addressSig);

    logger.d("[BOLTZ] boltz reverse swap request: ${request.toJson()}");

    // Response
    try {
      final apiResponse = await client.post(uri, data: request.toJson());

      final json = apiResponse.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz reverse swap response: $json");
      final swapResponse = BoltzCreateReverseSwapResponse.fromJson(json);

      // Verify that pubkey in returned invoice is the same we sent out
      final returnedPubkey = ref
          .read(addressParserProvider)
          .parseBoltzRoutingHintPubkey(swapResponse.invoice);
      logger.d(
          "[BOLTZ] boltz reverse swap - created pubkey: $publicKeyHex - returned pubkey: $returnedPubkey");

      if (returnedPubkey != publicKeyHex) {
        throw Exception(
            'Returned pubkey in boltz invoice does not match created pubkey.');
      }

      // Cache and add to swap checker streamer
      ref.read(boltzReverseSwapSuccessResponseProvider.notifier).state =
          swapResponse;
      ref
          .read(boltzStatusCheckProvider)
          .streamSingleSwapStatus(swapResponse.id);

      // Store preimage, private key, and response, and pairs (for fees) in secure storage until the swap is resolved
      final getPairsResponse = await getPairs();
      final boltzSwapData = BoltzReverseSwapData(
          created: DateTime.now(),
          request: request,
          response: swapResponse,
          fees: getPairsResponse,
          secureData: swapSecureData);
      await ref
          .read(boltzDataProvider)
          .saveBoltzReverseSwapData(boltzSwapData, swapResponse.id);

      return swapResponse;
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz reverse swap error: ${e.response?.statusCode}, ${e.response?.data}");
      ref.read(boltzErrorResponseProvider.notifier).state =
          e.response?.data.toString();
      return Future.error(e.response?.data);
    }
  }

  // ANCHOR: - Get Swap Status

  /// Get a single swap status
  Future<BoltzSwapStatusResponse> getSwapStatus(String id) async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}swapstatus';
    logger.d("[BOLTZ] swapstatus uri: $uri");

    try {
      final response = await client.post(
        uri,
        data: {'id': id},
      );

      final json = response.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz swap status response: $json");
      final statusResponse = BoltzSwapStatusResponse.fromJson(json);

      await cacheSwapStatus(swapId: id, swapStatus: statusResponse.status);

      await performClaimOrRefundIfNeeded(
          id, statusResponse.transaction?.hex, statusResponse.status);

      return statusResponse;
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz swap status error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // ANCHOR: - Fees
  Future<BoltzGetPairsResponse> getPairs() async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}getpairs';
    logger.d("[BOLTZ] getpairs uri: $uri");

    try {
      final response = await client.get(uri);
      final json = response.data as Map<String, dynamic>;

      if (json.containsKey('error')) {
        throw Exception('Error calling boltz getPairs');
      } else {
        final response = BoltzGetPairsResponse.fromJson(json);
        ref.read(boltzGetPairsStateProvider.notifier).state = response;
        return response;
      }
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz get pairs error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  /// Calculate total service fees for normal swap
  static int calculateTotalServiceFeesNormalSwap(BoltzSwapData swapData) {
    final fees = swapData.fees;
    if (fees == null) {
      logger.d("[Boltz] Error: Fees not cached on BoltzSwapData");
      return 0;
    }
    final onchainFee = fees.normalFee;
    final expectedAmount = swapData.response
        .expectedAmount; // this is what boltz expects to get, they take their fee from this the rest is the invoice amount
    final invoiceAmount =
        getAmountFromLightningInvoice(swapData.request.invoice);
    if (invoiceAmount == null) {
      return 0;
    }
    return expectedAmount - invoiceAmount + onchainFee;
  }

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
      logger.d("[Boltz] Could not parse amount from invoice");
      return null;
    }
  }

  /// Calculate total service fees from a reverse swap with a given `boltzGetPairsResponse` and `amount`
  static int calculateTotalServiceFeesReverse(BoltzReverseSwapData swapData) {
    final fees = swapData.fees;
    if (fees == null) {
      logger.d("[Boltz] Error: Fees not cached on BoltzReverseSwapData");
      return 0;
    }
    final amount = swapData.request.invoiceAmount;
    final totalServiceFeeSats = fees.reverseClaimFee +
        fees.reverseLockupFee +
        (fees.reversePercentage / 100 * amount);
    return totalServiceFeeSats.toInt();
  }

  /// Calculate the final amount received from a reverse swap minus total fees
  int getReceiveAmount() {
    final amount =
        ref.read(receiveAssetAmountForBip21Provider(Asset.lightning()));

    final amountAsDecimal =
        ref.read(parsedAssetAmountAsDecimalProvider(amount));
    final boltzGetPairsResponse =
        ref.watch(boltzGetPairsProvider).asData?.value;

    if (amountAsDecimal == Decimal.zero) {
      logger.e(
          '[BOLTZ] amountAsDouble is null. Should not be at getReceiveAmount()');
      return 0;
    }

    if (boltzGetPairsResponse != null) {
      int receiveSatoshiAmount;
      final totalServiceFeeSats = (boltzGetPairsResponse.reverseClaimFee +
              boltzGetPairsResponse.reverseLockupFee +
              (boltzGetPairsResponse.reversePercentage /
                  100 *
                  amountAsDecimal.toInt()))
          .round();
      receiveSatoshiAmount = amountAsDecimal.toInt() - totalServiceFeeSats;
      return receiveSatoshiAmount;
    }

    logger.e(
        '[BOLTZ] boltzGetPairsResponse is null. Should not be at getReceiveAmount()');
    return amountAsDecimal.toInt();
  }

  // ANCHOR: - Get Swap Status Stream

  /// Get a server-side events stream of swap status
  Stream<BoltzSwapStatusResponse> getSwapStatusStream(String id,
      {bool forceNewStream = false}) {
    if (!forceNewStream && _statusStreamControllers.containsKey(id)) {
      return _statusStreamControllers[id]!.stream;
    } else if (forceNewStream && _statusStreamControllers.containsKey(id)) {
      _closeSwapStatusStream(id);
    }

    // open new stream
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}streamswapstatus?id=$id';

    final sseStream =
        SSEClient.subscribeToSSE(method: SSERequestType.GET, url: uri, header: {
      "Accept": "text/event-stream",
      "Cache-Control": "no-cache",
    });

    final StreamController<BoltzSwapStatusResponse> controller =
        StreamController.broadcast();
    _statusStreamControllers[id] = controller;

    sseStream.listen((event) async {
      final eventJson = jsonDecode(event.data!);
      final eventResponse = BoltzSwapStatusResponse.fromJson(eventJson);

      await cacheSwapStatus(swapId: id, swapStatus: eventResponse.status);

      await performClaimOrRefundIfNeeded(
          id, eventResponse.transaction?.hex, eventResponse.status);

      controller.add(eventResponse);

      if (eventResponse.status.isFinal) {
        logger.d(
            "[BOLTZ] status ${eventResponse.status} is final - closing stream");
        await _closeSwapStatusStream(id);
      }
    }, onError: (error) {
      logger.e("[BOLTZ] Stream subscription error for $id: $error");
    });

    return controller.stream;
  }

  Future<void> _closeSwapStatusStream(String id) async {
    if (_statusStreamControllers.containsKey(id)) {
      await _statusStreamControllers[id]!.close();
      _statusStreamControllers.remove(id);
      logger.d('[BOLTZ] Closed status stream for: $id');
    }
  }

  // ANCHOR: - Perform claims and refunds
  Future<String?> performClaimOrRefundIfNeeded(
      String id, String? tx, BoltzSwapStatus status) async {
    if (status.needsClaim && tx != null) {
      final claimTx = await performClaim(id, tx);
      return claimTx;
    }

    if (status.needsRefund) {
      final lockupTXResponse = await fetchLockupTx(id);

      // If Boltz returns a timeoutEta, then the timeout has not been reached, and we can't send the refund yet
      if (lockupTXResponse.timeoutEta != null) {
        logger.d(
            '[BOLTZ] Refund timeout not yet reached: ${lockupTXResponse.timeoutEta}');
        return null;
      }

      try {
        String lockupTx = lockupTXResponse.transactionHex;
        final refundTx = await performRefund(id, lockupTx);
        return refundTx;
      } catch (e) {
        logger.e("[Boltz] refund error: $e");
        throw Exception(e);
      }
    }

    return null;
  }

  Future<String> performClaim(String id, String tx) async {
    try {
      // get swap data and construct claimData
      final swapData =
          await ref.read(boltzDataProvider).getBoltzReverseSwapData(id);
      if (swapData == null) {
        throw Exception('SwapData is null when trying to construct claim tx');
      }

      final address = await ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct claim tx');
      }

      if (swapData.secureData.preimageHex == null) {
        throw Exception(
            'PreimageHex is null when trying to construct claim tx');
      }

      final boltzGetPairsResponse = await getPairs();

      var claimTx = Elements.constructClaimTransaction(
        swapData.response.redeemScript,
        swapData.response.blindingKey,
        address.address!,
        swapData.secureData.privateKeyHex,
        swapData.secureData.preimageHex!,
        tx,
        boltzGetPairsResponse.reverseClaimFee,
      );
      logger.d('[BOLTZ] claim tx: $claimTx');

      // broadcast claim tx
      final broadcastTx = await broadcastTransaction(transactionHex: claimTx);
      logger
          .d('[BOLTZ] broadcast success - txId: ${broadcastTx.transactionId}');

      await cacheClaimTx(
          swapId: swapData.response.id, tx: broadcastTx.transactionId);

      return claimTx;
    } catch (e) {
      logger.e("[Boltz] claim error: $e");
      throw Exception(e);
    }
  }

  Future<String> performRefund(String id, String tx) async {
    try {
      // get swap data and construct refund data
      final swapData =
          await ref.read(boltzDataProvider).getBoltzNormalSwapData(id);
      if (swapData == null) {
        throw Exception('SwapData is null when trying to construct claim tx');
      }

      final address = await ref.read(liquidProvider).getReceiveAddress();
      if (address == null || address.address == null) {
        throw Exception(
            'Receive address is null when trying to construct claim tx');
      }

      final boltzGetPairsResponse = await getPairs();

      var refundTx = Elements.constructRefundTransaction(
        swapData.response.redeemScript,
        swapData.response.blindingKey,
        address.address!,
        swapData.secureData.privateKeyHex,
        tx,
        boltzGetPairsResponse.reverseClaimFee,
      );
      logger.d('[BOLTZ] refund tx: $refundTx');

      // broadcast refund tx
      final broadcastTx = await broadcastTransaction(transactionHex: refundTx);
      logger
          .d('[BOLTZ] broadcast success - txId: ${broadcastTx.transactionId}');

      await cacheRefundTx(
          swapId: swapData.response.id, tx: broadcastTx.transactionId);

      return broadcastTx.transactionId;
    } catch (e) {
      logger.e("[Boltz] refund error: $e");
      throw Exception(e);
    }
  }

  // ANCHOR: - Fetch Lockup Transaction

  /// Boltz docs: This call works for Normal Submarine Swaps only. If used for Reverse Submarine Swaps, the response will be:
  /// { "error": "could not find swap with id: CR8XaB" }
  Future<LockupTransactionResponse> fetchLockupTx(String swapId) async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));

    final uri = '${baseUri}getswaptransaction';
    logger.d("[BOLTZ] fetchLockupTx uri: $uri");

    try {
      final response = await client.post(uri, data: {'id': swapId});

      final json = response.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz fetchLockupTx response: $json");

      if (json.containsKey('error')) {
        throw Exception('Error calling boltz fetchLockupTx: ${json['error']}');
      } else {
        return LockupTransactionResponse.fromJson(json);
      }
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltzfetchLockupTxs error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // ANCHOR: - Fetch Reverse Swap Bip21

  /// Fetch bip21 for direct liquid send (this is a minor hack to fix an issue with Aqua > Aqua swaps)
  Future<BoltzReverseSwapBip21Response> fetchReverseSwapBip21(
      String lnInvoice) async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));

    final uri = '${baseUri}v2/swap/reverse/$lnInvoice/bip21';

    try {
      final response = await client.get(uri);

      final json = response.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz fetchReverseSwapBip21 response: $json");

      if (json.containsKey('error')) {
        throw Exception(
            'Error calling boltz fetchReverseSwapBip21: ${json['error']}');
      } else {
        return BoltzReverseSwapBip21Response.fromJson(json);
      }
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] fetchReverseSwapBip21 error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // ANCHOR: - Broadcast Transaction
  Future<BoltzBroadcastTransactionResponse> broadcastTransaction({
    String currency = "L-BTC",
    required String transactionHex,
  }) async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}broadcasttransaction';

    try {
      final response = await client.post(
        uri,
        data: {
          'currency': currency,
          'transactionHex': transactionHex,
        },
      );

      final json = response.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz broadcast transaction response: $json");

      if (json.containsKey('error')) {
        final errorResponse =
            BoltzBroadcastTransactionErrorResponse.fromJson(json);
        throw Exception(
            'Error broadcasting transaction: ${errorResponse.error}. Timeout ETA: ${errorResponse.timeoutEta}. Timeout Block Height: ${errorResponse.timeoutBlockHeight}');
      } else {
        return BoltzBroadcastTransactionResponse.fromJson(json);
      }
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz broadcast transaction error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // ANCHOR: - Send Onchain Normal Swap
  Future<GdkNewTransactionReply> createOnchainTxForCurrentNormalSwap() async {
    final boltzCurrentOrder =
        ref.read(boltzSwapSuccessResponseProvider.notifier).state;

    if (boltzCurrentOrder != null) {
      final tx = await ref
          .read(sendAssetTransactionProvider.notifier)
          .createGdkTransaction(
              address: boltzCurrentOrder.address,
              amountWithPrecision: boltzCurrentOrder.expectedAmount,
              asset: ref.read(manageAssetsProvider).lbtcAsset);

      logger.d('[BOLTZ] createGdkTransaction response: $tx}');
      return tx;
    } else {
      return Future.error('No current boltz order');
    }
  }

  // ANCHOR: - Caching
  Future<void> cacheTxHash(
      {required String swapId, required String txHash}) async {
    final boltzSwapData =
        await ref.read(boltzDataProvider).getBoltzNormalSwapData(swapId);
    if (boltzSwapData == null) {
      logger.d('[BOLTZ] error fetching stored swap data for swap: $swapId');
    }

    logger.d('[BOLTZ] caching final txhash: $txHash for swap: $swapId');

    final updatedSwapData = boltzSwapData!.copyWith(onchainTxHash: txHash);
    await ref
        .read(boltzDataProvider)
        .saveBoltzNormalSwapData(updatedSwapData, swapId);
  }

  Future<void> cacheClaimTx(
      {required String swapId, required String tx}) async {
    final boltzSwapData =
        await ref.read(boltzDataProvider).getBoltzReverseSwapData(swapId);
    if (boltzSwapData == null) {
      logger.d('[BOLTZ] error fetching stored swap data for swap: $swapId');
    }

    logger.d('[BOLTZ] caching claim tx: $tx for swap: $swapId');

    final updatedSwapData = boltzSwapData!.copyWith(claimTx: tx);
    await ref
        .read(boltzDataProvider)
        .saveBoltzReverseSwapData(updatedSwapData, swapId);
  }

  Future<void> cacheRefundTx(
      {required String swapId, required String tx}) async {
    final boltzSwapData =
        await ref.read(boltzDataProvider).getBoltzNormalSwapData(swapId);
    if (boltzSwapData == null) {
      logger.d('[BOLTZ] error fetching stored swap data for swap: $swapId');
    }

    logger.d('[BOLTZ] caching refund tx: $tx for swap: $swapId');

    final updatedSwapData = boltzSwapData!.copyWith(refundTx: tx);
    await ref
        .read(boltzDataProvider)
        .saveBoltzNormalSwapData(updatedSwapData, swapId);
  }

  Future<void> cacheSwapStatus(
      {required String swapId, required BoltzSwapStatus swapStatus}) async {
    // normal swaps
    final boltzSwapData =
        await ref.read(boltzDataProvider).getBoltzNormalSwapData(swapId);
    if (boltzSwapData != null) {
      final updatedSwapData = boltzSwapData.copyWith(swapStatus: swapStatus);
      await ref
          .read(boltzDataProvider)
          .saveBoltzNormalSwapData(updatedSwapData, swapId);
      return;
    }

    // reverse swaps
    final boltzReverseSwapData =
        await ref.read(boltzDataProvider).getBoltzReverseSwapData(swapId);
    if (boltzReverseSwapData != null) {
      final updatedSwapData =
          boltzReverseSwapData.copyWith(swapStatus: swapStatus);
      await ref
          .read(boltzDataProvider)
          .saveBoltzReverseSwapData(updatedSwapData, swapId);
      return;
    }
  }
}
