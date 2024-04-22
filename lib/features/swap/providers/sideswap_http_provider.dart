import 'dart:convert';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

final sideswapHttpProvider =
    Provider.autoDispose<SideswapHttpProvider>(SideswapHttpProvider.new);

class SideswapHttpProvider {
  final AutoDisposeProviderRef ref;

  SideswapHttpProvider(this.ref);

  Future<GdkCreatePsetDetailsReply> createPsetDetailsReply(
      SwapStartWebResult result) async {
    return Stream.value(null).map((_) {
      return GdkCreatePsetDetails(
        sendAsset: result.sendAsset,
        sendAmount: result.sendAmount,
        recvAsset: result.recvAsset,
        recvAmount: result.recvAmount,
      );
    }).switchMap((createDetails) {
      return Stream.value(null)
          .asyncMap(
              (_) async => ref.read(liquidProvider).createPset(createDetails))
          .map((createDetailsReply) {
        if (createDetailsReply == null) {
          throw SideswapHttpProcessStartNullCreateDetailsReply();
        }
        return createDetailsReply;
      });
    }).first;
  }

  Future<Map<String, dynamic>> httpStartWebParamsBody(
      GdkCreatePsetDetailsReply createDetailsReply,
      SwapStartWebResult result,
      Uri url) async {
    return Stream.value(null).map((_) {
      return HttpStartWebRequest(
        id: 1,
        method: 'swap_start',
        params: HttpStartWebParams(
          orderId: result.orderId,
          inputs: createDetailsReply.inputs,
          recvAddr: createDetailsReply.recvAddr,
          changeAddr: createDetailsReply.changeAddr,
          sendAsset: result.sendAsset,
          sendAmount: result.sendAmount,
          recvAsset: result.recvAsset,
          recvAmount: result.recvAmount,
        ),
      );
    }).asyncMap((httpStartWebRequest) async {
      //TODO - Replace with Dio
      return http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: httpStartWebRequest.toJsonString(),
      );
    }).map((httpResponse) {
      return jsonDecode(httpResponse.body) as Map<String, dynamic>;
    }).first;
  }

  Future<Map<String, dynamic>> httpBodySign(
    Map<String, dynamic> responseBody,
    SwapStartWebResult result,
    Uri url,
  ) async {
    return Stream.value(null).asyncMap((_) async {
      final bodyResult = responseBody["result"] as Map<String, dynamic>;
      final pset = bodyResult["pset"] as String;

      final signDetails = GdkSignPsetDetails(
          pset: pset,
          sendAsset: result.sendAsset,
          sendAmount: result.sendAmount,
          recvAsset: result.recvAsset,
          recvAmount: result.recvAmount);

      return ref.read(liquidProvider).signPset(signDetails);
    }).asyncMap((signResult) async {
      final httpBodySign = HttpSwapSignRequest(
        id: 1,
        method: 'swap_sign',
        params: HttpSwapSignParams(
          orderId: result.orderId,
          pset: signResult!.pset,
          submitId: responseBody["result"]["submit_id"] as String,
        ),
      );

      return http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: httpBodySign.toJsonString(),
      );
    }).map((httpResponse) {
      return jsonDecode(httpResponse.body) as Map<String, dynamic>;
    }).first;
  }
}

final startSwapProvider = Provider.autoDispose<bool>((ref) {
  final isSwapInProgress = ref.watch(swapProvider).isLoading;
  final isPegInProgress = ref.watch(pegProvider).isLoading;
  return isSwapInProgress || isPegInProgress;
});

class SideSwapProviderInvalidTransactionException implements Exception {}

class SideswapHttpProcessStartWrongData implements Exception {}

class SideswapHttpProcessStartNullCreateDetailsReply implements Exception {}
