import 'dart:async';
import 'dart:convert';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/external/boltz/storage/boltz_refund_data.dart';
import 'package:aqua/features/send/providers/send_asset_transaction_provider.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:convert/convert.dart';
import 'package:dio/dio.dart';

import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:aqua/common/crypto/generate_random_bytes.dart';
import 'package:aqua/common/crypto/secp256k1_key_pair.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/external/boltz/boltz.dart';
import 'package:pointycastle/export.dart';

import 'package:aqua/elements.dart';

const boltzMin = 1000;
const boltzMax = 25000000;
const boltzMinString = "1,000";
const boltzMaxString = "25,000,000";

final boltzGetPairsProvider =
    FutureProvider.autoDispose<BoltzGetPairsResponse>((ref) async {
  final client = ref.read(dioProvider);
  final baseUri = ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
  final uri = '$baseUri/getpairs';
  logger.d("[BOLTZ] getpairs uri: $uri");

  try {
    final response = await client.get(uri);

    final json = response.data as Map<String, dynamic>;
    logger.d("[BOLTZ] boltz getpairs response: $json");

    if (json.containsKey('error')) {
      throw Exception('Error calling boltz getPairs');
    } else {
      return BoltzGetPairsResponse.fromJson(json);
    }
  } on DioException catch (e) {
    logger.e(
        "[BOLTZ] boltz broadcast transaction error: ${e.response?.statusCode}, ${e.response?.data}");
    throw Exception(e);
  }
});

final boltzProvider = Provider.autoDispose<BoltzService>((ref) {
  return BoltzService(ref);
});

/////////////////////////////////////////
// Normal swap providers ////////////////

// cache initial call request - normal
final boltzSwapRequestProvider =
    StateProvider<BoltzCreateSwapRequest?>((ref) => null);

// cache initial call response - normal
final boltzSwapSuccessResponseProvider =
    StateProvider<BoltzCreateSwapResponse?>((ref) => null);

// cache gdk tx for normal swap
final boltzSwapGDKTransactionProvider =
    StateProvider<GdkNewTransactionReply?>((ref) => null);

/////////////////////////////////////////
// Reverse swap providers ///////////////

// cache initial call response - reverse
final boltzReverseSwapSuccessResponseProvider =
    StateProvider.autoDispose<BoltzCreateReverseSwapResponse?>((ref) => null);

// cache mempooltx from swapstatus update
// - this is also the point at which the claim tx can be broadcasted
final boltzReverseSwapMempoolTxProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/////////////////////////////////////////
// Swap status provider /////////////////
final boltzSwapStatusProvider = FutureProvider.autoDispose
    .family<BoltzSwapStatusResponse, String>((ref, id) {
  return ref.read(boltzProvider).getSwapStatus(id);
});

/// Fetches a boltz swap by the onchain tx hash
final boltzSwapFromTxHashProvider =
    FutureProvider.family<BoltzSwapData?, String>((ref, txhash) async {
  if (txhash.isEmpty) {
    return null;
  }

  return await ref
      .read(boltzDataProvider)
      .getBoltzNormalSwapDataByOnchainTx(txhash);
});

/// Forms refund data for a normal swap
final boltzSwapRefundDataProvider =
    FutureProvider.family<BoltzRefundData?, BoltzSwapData>(
        (ref, boltzSwapData) async {
  return BoltzRefundData(
      id: boltzSwapData.response.id,
      privateKey: boltzSwapData.secureData.privateKeyHex,
      blindingKey: boltzSwapData.response.blindingKey,
      redeemScript: boltzSwapData.response.redeemScript,
      timeoutBlockHeight: boltzSwapData.response.timeoutBlockHeight);
});

/////////////////////////////////////////
// Error provider ///////////////////////
final boltzErrorResponseProvider =
    StateProvider.autoDispose<String?>((ref) => null);

/////////////////////////////////////////
// Main boltz provider //////////////////
class BoltzService {
  final AutoDisposeProviderRef ref;

  BoltzService(this.ref);

  // ANCHOR: - Create Swap

  /// Create Onchain to Lightning swap
  Stream<AsyncValue<BoltzCreateSwapResponse>> createSwap({
    required String invoice,
    required BuildContext context,
  }) async* {
    yield const AsyncValue.loading();

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
      pairId: PairId.LBTC_BTC,
      orderSide: OrderSide.sell,
      invoice: invoice,
      refundPublicKey: publicKeyHex,
      referralId: 'AQUA',
    );

    logger.d("[BOLTZ] boltz swap request: ${request.toJson()}");

    // cache request
    ref.read(boltzSwapRequestProvider.notifier).state = request;

    // Response
    try {
      final apiResponse = await client.post(uri, data: request.toJson());

      final json = apiResponse.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz swap response: $json");
      final swapResponse = BoltzCreateSwapResponse.fromJson(json);

      // cache response
      ref.read(boltzSwapSuccessResponseProvider.notifier).state = swapResponse;

      final bolt11Result = Bolt11PaymentRequest(invoice);
      final preimageInInvoice = bolt11Result.tags
          .firstWhere(
            (tag) => tag.type == 'payment_hash',
            orElse: () => throw Exception(
                '[BOLTZ] Redeem script from response cannot parse payment_hash'),
          )
          .data
          .toString();

      final redeemScriptFromBoltz = swapResponse.redeemScript;
      var claimPublicKeyFromBoltz =
          Elements.extractPublicKeyFromRedeemScript(redeemScriptFromBoltz);
      var reconstructedRedeemScript = Elements.constructRedeemScript(
          preimageInInvoice,
          claimPublicKeyFromBoltz,
          request.refundPublicKey,
          swapResponse.timeoutBlockHeight);

      if (redeemScriptFromBoltz != reconstructedRedeemScript) {
        ref.read(boltzErrorResponseProvider.notifier).state =
            AppLocalizations.of(context)!.boltzRedeemScriptValidationError;
        yield AsyncValue.error(
            AppLocalizations.of(context)!.boltzRedeemScriptValidationError,
            StackTrace.empty);
        return;
      }

      // Store preimage, private key, and response in secure storage until the swap is resolved
      final boltzSwapData = BoltzSwapData(
          request: request, response: swapResponse, secureData: swapSecureData);
      await ref
          .read(boltzDataProvider)
          .saveBoltzNormalSwapData(boltzSwapData, swapResponse.id);

      // Send onchain swap payment
      yield AsyncValue.data(swapResponse);
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz swap error: ${e.response?.statusCode}, ${e.response?.data}");
      ref.read(boltzErrorResponseProvider.notifier).state =
          e.response?.data.toString();
      yield AsyncValue.error(e.response?.data, StackTrace.empty);
    }
  }

  // ANCHOR: - Create Reverse Swap

  /// Lightning to Onchain swap
  Stream<AsyncValue<BoltzCreateReverseSwapResponse>> createReverseSwap(
      int invoiceAmount) async* {
    yield const AsyncValue.loading();

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

    // Key pair generation using secp256k1
    final keyPair = secp256k1KeyPair();
    final privateKeyHex = privateKeyToHex(keyPair.privateKey as ECPrivateKey);
    final publicKeyHex = publicKeyToHex(keyPair.publicKey as ECPublicKey);

    // Secure storage
    final swapSecureData = BoltzSwapSecureData(
        privateKeyHex: privateKeyHex, preimageHex: preimageHex);
    logger.d('[BOLTZ] public key: $publicKeyHex');
    logger.d('[BOLTZ] preimageHash: $preimageHash');
    logger.d('[BOLTZ] preimageHashHex: $preimageHashHex');

    // Request
    final request = BoltzCreateReverseSwapRequest(
        type: SwapType.reversesubmarine,
        pairId: PairId.LBTC_BTC,
        orderSide: OrderSide.buy,
        invoiceAmount: invoiceAmount,
        claimPublicKey: publicKeyHex,
        preimageHash: preimageHashHex);

    logger.d("[BOLTZ] boltz reverse swap request: ${request.toJson()}");

    // Response
    try {
      final apiResponse = await client.post(uri, data: request.toJson());

      final json = apiResponse.data as Map<String, dynamic>;
      logger.d("[BOLTZ] boltz reverse swap response: $json");
      final swapResponse = BoltzCreateReverseSwapResponse.fromJson(json);
      ref.read(boltzReverseSwapSuccessResponseProvider.notifier).state =
          swapResponse;

      // Store preimage, private key, and response in secure storage until the swap is resolved
      final boltzSwapData = BoltzReverseSwapData(
          request: request, response: swapResponse, secureData: swapSecureData);
      await ref
          .read(boltzDataProvider)
          .saveBoltzReverseSwapData(boltzSwapData, swapResponse.id);

      yield AsyncValue.data(swapResponse);
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz reverse swap error: ${e.response?.statusCode}, ${e.response?.data}");
      ref.read(boltzErrorResponseProvider.notifier).state =
          e.response?.data.toString();
      yield AsyncValue.error(e.response?.data, StackTrace.empty);
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

      // cache mempool tx
      if (statusResponse.status == BoltzSwapStatus.transactionMempool) {
        ref.read(boltzReverseSwapMempoolTxProvider.notifier).state =
            statusResponse.transaction!.hex;
      }

      return statusResponse;
    } on DioException catch (e) {
      logger.e(
          "[BOLTZ] boltz swap status error: ${e.response?.statusCode}, ${e.response?.data}");
      throw Exception(e);
    }
  }

  // ANCHOR: - Get Swap Status Stream

  /// Get a server-side events stream of swap status
  Stream<BoltzSwapStatusResponse> getSwapStatusStream(String id) {
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '${baseUri}streamswapstatus?id=$id';
    logger.d("[BOLTZ] streamswapstatus uri: $uri");

    final sseStream =
        SSEClient.subscribeToSSE(method: SSERequestType.GET, url: uri, header: {
      "Accept": "text/event-stream",
      "Cache-Control": "no-cache",
    });

    return sseStream.asyncMap((event) async {
      final eventJson = jsonDecode(event.data!);
      final eventResponse = BoltzSwapStatusResponse.fromJson(eventJson);

      // cache mempool tx
      if (eventResponse.status == BoltzSwapStatus.transactionMempool) {
        ref.read(boltzReverseSwapMempoolTxProvider.notifier).state =
            eventResponse.transaction!.hex;
      }

      // call claim if transaction is confirmed or in mempool
      if (eventResponse.status.isPending) {
        performClaim().listen((result) {
          logger.d('[BOLTZ] perform claim stream: $result');
        });
      }

      return eventResponse;
    });
  }

  // ANCHOR: - Perform claim

  Stream<String> performClaim() async* {
    // get mempool tx to kick off claim
    final mempoolTx =
        ref.watch(boltzReverseSwapMempoolTxProvider.notifier).state;
    if (mempoolTx == null) {
      throw Exception(
          '[Boltz] mempoolTx is null when trying to construct claim tx');
    }

    //get swap data and construct claimData
    final swapId = ref.read(boltzReverseSwapSuccessResponseProvider)?.id;
    if (swapId == null) {
      throw Exception(
          '[BOLTZ] Swap ID is null when trying to construct claim tx');
    }
    final swapData =
        await ref.read(boltzDataProvider).getBoltzReverseSwapData(swapId);
    if (swapData == null) {
      throw Exception(
          '[BOLTZ] swapData is null when trying to construct claim tx');
    }

    //TODO: Call liquid library to construct claim tx
    yield '';
  }

  // ANCHOR: - Broadcast Transaction
  Future<BoltzBroadcastTransactionResponse> broadcastTransaction({
    required String currency,
    required String transactionHex,
  }) async {
    final client = ref.read(dioProvider);
    final baseUri =
        ref.read(boltzEnvConfigProvider.select((env) => env.apiUrl));
    final uri = '$baseUri/broadcasttransaction';
    logger.d("[BOLTZ] broadcasttransaction uri: $uri");

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

  // create tx
  Future<GdkNewTransactionReply> createOnchainNormalSwap({
    required BoltzCreateSwapResponse createSwapResponse,
  }) async {
    final tx = await ref
        .read(sendAssetTransactionProvider.notifier)
        .createTransaction(
            amountSatoshi: createSwapResponse.expectedAmount,
            sendAll: false,
            address: createSwapResponse.address,
            network: NetworkType.liquid,
            assetId: ref.read(liquidProvider).lbtcId);

    // cache tx to provider
    ref.read(boltzSwapGDKTransactionProvider.notifier).state = tx;

    logger.d('[BOLTZ] createGdkTransaction response: $tx}');
    return tx;
  }

  void cacheTxHash({required String swapId, required String txHash}) async {
    // cache tx to swap data persistence
    final boltzSwapData =
        await ref.read(boltzDataProvider).getBoltzNormalSwapData(swapId);
    if (boltzSwapData == null) {
      logger.d('[BOLTZ] error fetching stored swap data for swap: $swapId');
    }

    logger.d('[BOLTZ] caching final txhash: $txHash for swap: $swapId');

    final updatedSwapData = boltzSwapData!.withOnchainTxHash(txHash);
    await ref
        .read(boltzDataProvider)
        .saveBoltzNormalSwapData(updatedSwapData, swapId);

    logger.d('[TX] create onchain normal swap with tx hash: $txHash');
  }
}
