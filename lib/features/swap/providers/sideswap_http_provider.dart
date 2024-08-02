import 'dart:convert';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:http/http.dart' as http;

final sideswapHttpProvider =
    Provider.autoDispose<SideswapHttpProvider>(SideswapHttpProvider.new);

class SideswapHttpProvider {
  final AutoDisposeProviderRef ref;

  SideswapHttpProvider(this.ref);

  Future<Map<String, dynamic>> httpStartWebParamsBody(
      HttpStartWebParams payload, SwapStartWebResult result, Uri url) async {
    return Stream.value(null).map((_) {
      return HttpStartWebRequest(
        id: 1,
        method: 'swap_start',
        params: payload,
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
    String signedPset,
    SwapStartWebResult result,
    String submitId,
    Uri url,
  ) async {
    final payload = HttpSwapSignRequest(
      id: 1,
      method: 'swap_sign',
      params: HttpSwapSignParams(
        orderId: result.orderId,
        pset: signedPset,
        submitId: submitId,
      ),
    );

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: payload.toJsonString(),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class SideSwapProviderInvalidTransactionException implements Exception {}

class SideswapHttpProcessStartWrongData implements Exception {}

class SideswapHttpProcessStartNullCreateDetailsReply implements Exception {}
