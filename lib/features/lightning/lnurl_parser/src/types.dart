class LNURLErrorResponse {
  LNURLErrorResponse.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        reason = json['reason'],
        domain = json['domain'],
        url = json['url'];
  final String? status;
  final String? reason;
  final String? domain;
  final String? url;
}

class LNURLChannelParams {
  LNURLChannelParams.fromJson(Map<String, dynamic> json)
      : tag = json['tag'],
        callback = json['callback'],
        domain = json['domain'],
        k1 = json['k1'],
        url = json['url'];
  final String? tag;
  final String? callback;
  final String? domain;
  final String? k1;
  final String? url;
}

class LNURLWithdrawParams {
  LNURLWithdrawParams.fromJson(Map<String, dynamic> json)
      : tag = json['tag'],
        k1 = json['k1'],
        callback = json['callback'],
        domain = json['domain'],
        minWithdrawable = json['minWithdrawable'] ?? 0,
        maxWithdrawable = json['maxWithdrawable'] ?? 0,
        defaultDescription = json['defaultDescription'];
  final String? tag;
  final String? k1;
  final String? callback;
  final String? domain;
  final int minWithdrawable;
  final int maxWithdrawable;
  final String? defaultDescription;
}

class LNURLWithdrawResult {
  LNURLWithdrawResult.fromJson(Map<String, dynamic> json)
      : pr = json['pr'],
        errorResponse = json['status'] == 'ERROR'
            ? LNURLErrorResponse.fromJson(json)
            : null;
  final String? pr;
  final LNURLErrorResponse? errorResponse;
}

class LNURLAuthParams {
  LNURLAuthParams.fromJson(Map<String, dynamic> json)
      : tag = json['tag'],
        k1 = json['k1'],
        callback = json['callback'],
        domain = json['domain'];
  final String? tag;
  final String? k1;
  final String? callback;
  final String? domain;
}

class LNURLPayParams {
  LNURLPayParams.fromJson(Map<String, dynamic> json)
      : tag = json['tag'],
        callback = json['callback'],
        minSendable = json['minSendable'] ?? 0,
        maxSendable = json['maxSendable'] ?? 0,
        metadata = json['metadata'];
  final String? tag;
  final String? callback;
  final int minSendable; // returned in millisats
  final int maxSendable; // returned in millisats
  final String? metadata;

  int get minSendableSats => minSendable ~/ 1000;
  int get maxSendableSats => maxSendable ~/ 1000;

  bool get isFixedAmount => minSendable == maxSendable;
}

/// A success action will be returned when making a call to the lnUrl callback url.
class LNURLPaySuccessAction {
  LNURLPaySuccessAction.fromJson(Map<String, dynamic> json)
      : tag = json['tag'],
        description = json['description'],
        url = json['url'],
        message = json['message'],
        cipherText = json['cipherText'] ?? '',
        iv = json['iv'] ?? '';
  final String? tag;
  final String? description;
  final String? url;
  final String? message;
  final String cipherText;
  final String iv;
}

class LNURLPayResult {
  LNURLPayResult.fromJson(Map<String, dynamic> json)
      : pr = json['pr'],
        successAction = json['successAction'] != null
            ? LNURLPaySuccessAction.fromJson(json['successAction'])
            : null,
        errorResponse = json['status'] == 'ERROR'
            ? LNURLErrorResponse.fromJson(json)
            : null,
        disposable = json['disposable'] ?? false,
        routes = (json['routes'] as List<dynamic>?)
            ?.map((e) => e as List<Object>)
            .toList();
  final String pr;
  final LNURLPaySuccessAction? successAction;
  final LNURLErrorResponse? errorResponse;
  final bool disposable;
  final List<List<dynamic>>? routes;
}

/// The result returned when you call getParams. The correct response
/// item will be non-null and the rest will be null.
///
/// If error is non-null then an error occurred while calling the lnurl service.
class LNURLParseResult {
  LNURLParseResult({
    this.withdrawalParams,
    this.payParams,
    this.authParams,
    this.channelParams,
    this.error,
  });
  final LNURLWithdrawParams? withdrawalParams;
  final LNURLPayParams? payParams;
  final LNURLAuthParams? authParams;
  final LNURLChannelParams? channelParams;
  final LNURLErrorResponse? error;

  bool get isLnurlPayFixedAmount =>
      payParams != null && payParams!.isFixedAmount;
}
