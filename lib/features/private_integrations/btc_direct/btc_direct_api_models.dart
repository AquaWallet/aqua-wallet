import 'package:freezed_annotation/freezed_annotation.dart';

part 'btc_direct_api_models.freezed.dart';
part 'btc_direct_api_models.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    required String refreshToken,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class BTCPriceResponse with _$BTCPriceResponse {
  const factory BTCPriceResponse({
    required String buyPrice,
    required String sellPrice,
  }) = _BTCPriceResponse;

  factory BTCPriceResponse.fromJson(Map<String, dynamic> json) {
    final buy = json['buy'] as Map<String, dynamic>;
    final sell = json['sell'] as Map<String, dynamic>;

    return BTCPriceResponse(
      buyPrice: buy['BTC-EUR'].toString(),
      sellPrice: sell['BTC-EUR'].toString(),
    );
  }
}

@freezed
class CheckoutRequest with _$CheckoutRequest {
  const factory CheckoutRequest({
    required String baseCurrency,
    required String quoteCurrency,
    required String walletAddress,
    double? baseCurrencyAmount,
    double? quoteCurrencyAmount,
    required String returnUrl,
    String? paymentMethod,
    @Default(false) bool fixedAmount,
    @Default(false) bool showWalletAddress,
  }) = _CheckoutRequest;

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckoutRequestFromJson(json);
}

@freezed
class CheckoutResponse with _$CheckoutResponse {
  const factory CheckoutResponse({
    required String checkoutUrl,
    String? orderId,
  }) = _CheckoutResponse;

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckoutResponseFromJson(json);
}

@freezed
class UserRegistrationRequest with _$UserRegistrationRequest {
  const factory UserRegistrationRequest({
    required String identifier,
    String? returnUrl,
  }) = _UserRegistrationRequest;

  factory UserRegistrationRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRegistrationRequestFromJson(json);
}

@freezed
class PaymentMethodFees with _$PaymentMethodFees {
  const factory PaymentMethodFees({
    required double fixed,
    required double percentage,
  }) = _PaymentMethodFees;

  factory PaymentMethodFees.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFeesFromJson(json);
}

@freezed
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    required String code,
    required String label,
    required double limit,
    required PaymentMethodFees fee,
    required int expirationPeriod,
    required bool openInNewTab,
  }) = _PaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

@freezed
class PaymentMethodsResponse with _$PaymentMethodsResponse {
  const factory PaymentMethodsResponse({
    required List<PaymentMethod> paymentMethods,
    required Map<String, List<String>> countries,
  }) = _PaymentMethodsResponse;

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) {
    final paymentMethodsList = (json['paymentMethods'] as List)
        .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();

    final countriesMap = Map<String, List<String>>.from(
      (json['countries'] as Map).map(
        (key, value) => MapEntry(
          key as String,
          (value as List).map((e) => e as String).toList(),
        ),
      ),
    );

    return PaymentMethodsResponse(
      paymentMethods: paymentMethodsList,
      countries: countriesMap,
    );
  }
}
