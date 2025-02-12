import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_models.freezed.dart';
part 'api_models.g.dart';

enum Currency {
  @JsonValue('BTC')
  btc,
  @JsonValue('USDT')
  usdt,
}

enum Blockchain {
  @JsonValue('BITCOIN')
  bitcoin,
  @JsonValue('LIQUID')
  liquid,
}

@freezed
class LoginRequest with _$LoginRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LoginRequest({
    required String email,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class VerifyRequest with _$VerifyRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory VerifyRequest({
    required String email,
    required String otpCode,
  }) = _VerifyRequest;

  factory VerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyRequestFromJson(json);
}

@freezed
class MessageResponse with _$MessageResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MessageResponse({
    required String message,
  }) = _MessageResponse;

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);
}

@freezed
class AuthTokenResponse with _$AuthTokenResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AuthTokenResponse({
    required String access,
    required String refresh,
  }) = _AuthTokenResponse;

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);
}

@freezed
class ProfileResponse with _$ProfileResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ProfileResponse({
    required String id,
    required String email,
    required DateTime? lastLogin,
    required bool isSuperuser,
    required bool isStaff,
    required bool isActive,
    required DateTime dateJoined,
    required List<int> groups,
    required List<int> userPermissions,
  }) = _ProfileResponse;

  factory ProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseFromJson(json);
}

@freezed
class ExchangeRateResponse with _$ExchangeRateResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ExchangeRateResponse({
    required String name,
    required String cryptoCode,
    required String currencyPair,
    required String code,
    required String rate,
  }) = _ExchangeRateResponse;

  factory ExchangeRateResponse.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateResponseFromJson(json);
}

@freezed
class RefreshTokenRequest with _$RefreshTokenRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RefreshTokenRequest({
    required String refresh,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

@freezed
class CardCreationRequest with _$CardCreationRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CardCreationRequest({
    String? name,
    String? style,
  }) = _CardCreationRequest;

  factory CardCreationRequest.fromJson(Map<String, dynamic> json) =>
      _$CardCreationRequestFromJson(json);
}

@freezed
class AmountRequest with _$AmountRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AmountRequest({
    required String usdAmount,
  }) = _AmountRequest;

  factory AmountRequest.fromJson(Map<String, dynamic> json) =>
      _$AmountRequestFromJson(json);
}

@freezed
class InvoiceRequest with _$InvoiceRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory InvoiceRequest({
    required String usdAmount,
    required Currency currency,
    required Blockchain blockchain,
    required String cardId,
  }) = _InvoiceRequest;

  factory InvoiceRequest.fromJson(Map<String, dynamic> json) =>
      _$InvoiceRequestFromJson(json);
}

@freezed
class AccessTokenResponse with _$AccessTokenResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AccessTokenResponse({
    required String access,
  }) = _AccessTokenResponse;

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AccessTokenResponseFromJson(json);
}

@freezed
class DailyPriceResponse with _$DailyPriceResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DailyPriceResponse({
    required DateTime timestamp,
    required String price,
  }) = _DailyPriceResponse;

  factory DailyPriceResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyPriceResponseFromJson(json);
}

@freezed
class HealthResponse with _$HealthResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory HealthResponse({
    required String databaseStatus,
  }) = _HealthResponse;

  factory HealthResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthResponseFromJson(json);
}

@freezed
class CardListResponse with _$CardListResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CardListResponse({
    required List<CardResponse> cards,
    PaginationInfoModel? pagination,
  }) = _CardListResponse;

  factory CardListResponse.fromJson(Map<String, dynamic> json) =>
      _$CardListResponseFromJson(json);
}

@freezed
class CardResponse with _$CardResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CardResponse({
    required String id,
    @Default(0) double availableBalance,
    @Default(0) double balance,
    required DateTime expiration,
    required String displayExpiration,
    required bool terminated,
    required String cardProductId,
    required String pan,
    //TODO - Temp nullable due to bug on moonpay backend
    String? cvv,
    required String supportToken,
    required bool frozen,
    String? name,
    @JsonKey(fromJson: cardStyleFromString)
    @Default(CardStyle.style1)
    CardStyle style,
    required String user,
    required Map<String, String?> giftCardInfo,
  }) = _CardResponse;

  factory CardResponse.fromJson(Map<String, dynamic> json) =>
      _$CardResponseFromJson(json);
}

@freezed
class AddBalanceResponse with _$AddBalanceResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AddBalanceResponse({
    required String id,
    required String token,
    required String pan,
    required String cvv,
    required DateTime expiration,
    required String balance,
    required String availableBalance,
    required String supportToken,
  }) = _AddBalanceResponse;

  factory AddBalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$AddBalanceResponseFromJson(json);
}

@freezed
class GenerateInvoiceResponse with _$GenerateInvoiceResponse {
  // @JsonSerializable(fieldRename: FieldRename.snake)
  const factory GenerateInvoiceResponse({
    required String id,
    required String address,
    required double usdAmountOwed,
    required double cryptoAmountOwed,
    required int exchangeRateLockExpiration,
    required Blockchain blockchain,
    required Currency currency,
  }) = _GenerateInvoiceResponse;

  factory GenerateInvoiceResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateInvoiceResponseFromJson(json);
}

@freezed
class PaginationInfoModel with _$PaginationInfoModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PaginationInfoModel({
    @Default(0) int currentPage,
    @Default(0) int fromField,
    @Default(0) int lastPage,
    @Default(0) int perPage,
    @Default(0) int total,
  }) = _PaginationInfoModel;

  factory PaginationInfoModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoModelFromJson(json);
}
