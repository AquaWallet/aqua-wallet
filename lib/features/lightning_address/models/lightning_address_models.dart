import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'lightning_address_models.freezed.dart';
part 'lightning_address_models.g.dart';

const kAquaNetDomain = '@aqua.net';

@freezed
class LightningAddressState with _$LightningAddressState {
  const factory LightningAddressState({
    required String address,
    required bool isToggled,
  }) = _LightningAddressState;
}

@freezed
class IsLnUsernameAvailableResponse with _$IsLnUsernameAvailableResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory IsLnUsernameAvailableResponse({
    required bool isAvailable,
  }) = _IsLnUsernameAvailableResponse;

  factory IsLnUsernameAvailableResponse.fromJson(Map<String, dynamic> json) =>
      _$IsLnUsernameAvailableResponseFromJson(json);
}

@freezed
class RegisterAddressesRequest with _$RegisterAddressesRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RegisterAddressesRequest({
    @JsonKey(name: 'fingerprint') required String fingerPrint,
    required List<String> addresses,
  }) = _RegisterAddressesRequest;

  factory RegisterAddressesRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterAddressesRequestFromJson(json);
}

@freezed
class LnAddressEditFormState with _$LnAddressEditFormState {
  const LnAddressEditFormState._();

  const factory LnAddressEditFormState({
    required String currentUsername,
    required String inputUsername,
    @Default(null) bool? isAvailable,
    Asset? selectedAsset,
  }) = _LnAddressEditFormState;

  String get newAddress => '$inputUsername$kAquaNetDomain';

  bool get isUnavailable =>
      inputUsername.isNotEmpty &&
      inputUsername != currentUsername &&
      isAvailable == false;

  bool get isNextEnabled =>
      inputUsername.isNotEmpty &&
      inputUsername != currentUsername &&
      isAvailable == true;
}

enum PaymentRequestProductType {
  @JsonValue('LN_USERNAME_UPDATE')
  lnUsernameUpdate,
}

enum LiquidWalletProductType {
  @JsonValue('LN_USERNAME_UPDATE')
  lnUsernameUpdate,
}

extension LiquidWalletProductTypeExt on LiquidWalletProductType {
  String get apiValue => _$LiquidWalletProductTypeEnumMap[this]!;
}

@freezed
class LiquidWalletProduct with _$LiquidWalletProduct {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory LiquidWalletProduct({
    required LiquidWalletProductType productType,
    required int lbtcSatsPrice,
    required int usdtBaseUnitsPrice,
    required String usdtDisplayPrice,
  }) = _LiquidWalletProduct;

  factory LiquidWalletProduct.fromJson(Map<String, dynamic> json) =>
      _$LiquidWalletProductFromJson(json);
}

enum PaymentAssetTicker {
  @JsonValue('L-BTC')
  lbtc,
  @JsonValue('USDt')
  usdt,
}

@freezed
class PaymentRequest with _$PaymentRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PaymentRequest({
    required PaymentAssetTicker asset,
    required String lnUsername,
  }) = _PaymentRequest;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);
}

@freezed
class PaymentResponse with _$PaymentResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PaymentResponse({
    required String paymentId,
    required String status,
    required PaymentRequestProductType productType,
    required PaymentAssetTicker assetTicker,
    required String amount,
    required int amountBaseUnits,
    required String address,
    required DateTime expiresAt,
  }) = _PaymentResponse;

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);
}

@freezed
class SubmitSignedTxRequest with _$SubmitSignedTxRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory SubmitSignedTxRequest({
    required String paymentId,
    required String rawTx,
  }) = _SubmitSignedTxRequest;

  factory SubmitSignedTxRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitSignedTxRequestFromJson(json);
}
