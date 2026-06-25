import 'package:freezed_annotation/freezed_annotation.dart';

part 'depix_models.freezed.dart';
part 'depix_models.g.dart';

enum EulenDepositStatus {
  canceled,
  underReview,
  depixSent,
  error,
  refunded,
  expired,
  pending,
  pendingPix2fa,
  delayed,
  unknown;

  static EulenDepositStatus parse(Object? json) => switch (json?.toString()) {
        'canceled' => canceled,
        'under_review' => underReview,
        'depix_sent' => depixSent,
        'error' => error,
        'refunded' => refunded,
        'expired' => expired,
        'pending' => pending,
        'pending_pix2fa' => pendingPix2fa,
        'delayed' => delayed,
        _ => unknown,
      };

  String toJson() => switch (this) {
        underReview => 'under_review',
        depixSent => 'depix_sent',
        pendingPix2fa => 'pending_pix2fa',
        unknown => '',
        _ => name,
      };

  bool get isPending => this == pending;
  bool get isUnderReview => this == underReview;
}

EulenDepositStatus eulenDepositStatusFromJson(Object? json) =>
    EulenDepositStatus.parse(json);

String eulenDepositStatusToJson(EulenDepositStatus status) => status.toJson();

@freezed
class EulenDeposit with _$EulenDeposit {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EulenDeposit({
    required int depositId,
    required String eulenDepositId,
    @JsonKey(
        fromJson: eulenDepositStatusFromJson, toJson: eulenDepositStatusToJson)
    required EulenDepositStatus status,
    required int amountBrlCents,
    required String depixAddress,
    required String? qrCopyPaste,
    required String? qrImageUrl,
    String? blockchainTxId,
    required DateTime created,
    required DateTime modified,
  }) = _EulenDeposit;

  factory EulenDeposit.fromJson(Map<String, dynamic> json) =>
      _$EulenDepositFromJson(json);
}

@freezed
class EulenDepositsResponse with _$EulenDepositsResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EulenDepositsResponse({
    required List<EulenDeposit> deposits,
    required int count,
  }) = _EulenDepositsResponse;

  factory EulenDepositsResponse.fromJson(Map<String, dynamic> json) =>
      _$EulenDepositsResponseFromJson(json);
}

@freezed
class EulenDepositRequest with _$EulenDepositRequest {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EulenDepositRequest({
    required int amountBrlCents,
    required String liquidDepixAddress,
  }) = _EulenDepositRequest;

  factory EulenDepositRequest.fromJson(Map<String, dynamic> json) =>
      _$EulenDepositRequestFromJson(json);
}

@freezed
class EulenDepositResponse with _$EulenDepositResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EulenDepositResponse({
    required String qrCopyPaste,
    required String qrImageUrl,
    required int depositId,
  }) = _EulenDepositResponse;

  factory EulenDepositResponse.fromJson(Map<String, dynamic> json) =>
      _$EulenDepositResponseFromJson(json);
}

@freezed
class EulenPixDepixFeeResponse with _$EulenPixDepixFeeResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory EulenPixDepixFeeResponse({
    required int pixDepixFeeBrlCents,
  }) = _EulenPixDepixFeeResponse;

  factory EulenPixDepixFeeResponse.fromJson(Map<String, dynamic> json) =>
      _$EulenPixDepixFeeResponseFromJson(json);
}
