import 'package:freezed_annotation/freezed_annotation.dart';

part 'lending_models.freezed.dart';
part 'lending_models.g.dart';

/// Base loan offer model
@freezed
class LoanOffer with _$LoanOffer {
  const factory LoanOffer({
    required String id,
    required String name,
    required double minAmount,
    required double maxAmount,
    required int minDurationDays,
    required int maxDurationDays,
    required double interestRate,
    required double minCollateralRatio,
    required String repaymentAddress,
    required List<OriginationFee> originationFees,
    required List<OriginationFee> extensionFees,
    required LenderInfo lender,
    required LoanOfferStatus status,
    required LoanAsset asset,
    required String lenderPk,
    String? kycLink,
  }) = _LoanOffer;
}

/// Base loan contract model
@freezed
class LoanContract with _$LoanContract {
  const factory LoanContract({
    required String id,
    required double amount,
    required int durationDays,
    required int collateralAmountSats,
    required int initialCollateralSats,
    required int originationFeeSats,
    required double interestRate,
    required double initialCollateralRatio,
    required LoanAsset asset,
    required ContractStatus status,
    required String borrowerAddress,
    required String repaymentAddress,
    required LenderInfo lender,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime expiresAt,
    required LiquidationStatus liquidationStatus,
    required List<LoanTransaction> transactions,
    required LoanType type,
    required double liquidationPrice,
    required String borrowerPk,
    String? borrowerDerivationPath,
    required String lenderPk,
    required double interest,
    required String lenderNpub,
    required List<TimelineEvent> timeline,
    String? borrowerLoanAddress,
    String? contractAddress,
    String? extendedByContract,
    String? extendsContract,
    DateTime? repaidAt,
  }) = _LoanContract;

  factory LoanContract.fromJson(Map<String, dynamic> json) =>
      _$LoanContractFromJson(json);
}

/// Base lender information
@freezed
class LenderInfo with _$LenderInfo {
  const factory LenderInfo({
    required String id,
    required String name,
    required int successfulContracts,
    required int failedContracts,
    required double rating,
    required DateTime joinedAt,
    String? timezone,
  }) = _LenderInfo;

  factory LenderInfo.fromJson(Map<String, dynamic> json) =>
      _$LenderInfoFromJson(json);
}

/// Base origination fee model
@freezed
class OriginationFee with _$OriginationFee {
  const factory OriginationFee({
    required int fromDay,
    required int toDay,
    required double fee,
  }) = _OriginationFee;

  factory OriginationFee.fromJson(Map<String, dynamic> json) =>
      _$OriginationFeeFromJson(json);
}

/// Base loan transaction model
@freezed
class LoanTransaction with _$LoanTransaction {
  const factory LoanTransaction({
    required String id,
    required String txid,
    required String contractId,
    required LendasatTransactionType type,
    required DateTime timestamp,
  }) = _LoanTransaction;

  factory LoanTransaction.fromJson(Map<String, dynamic> json) =>
      _$LoanTransactionFromJson(json);
}

/// Base contract request model
@freezed
class ContractRequest with _$ContractRequest {
  const factory ContractRequest({
    required String id,
    required double loanAmount,
    required int durationDays,
    required String borrowerBtcAddress,
    required String borrowerPk,
    required String borrowerDerivationPath,
    required String borrowerNpub,
    required LoanType loanType,
    String? borrowerLoanAddress,
  }) = _ContractRequest;

  factory ContractRequest.fromJson(Map<String, dynamic> json) =>
      _$ContractRequestFromJson(json);
}

/// Base collateral PSBT model
@freezed
class CollateralPsbt with _$CollateralPsbt {
  const factory CollateralPsbt({
    required String psbt,

    /// this is a miniscript descriptor. You might not need it
    required String collateralDescriptor,
    required String borrowerPk,
  }) = _CollateralPsbt;

  factory CollateralPsbt.fromJson(Map<String, dynamic> json) =>
      _$CollateralPsbtFromJson(json);
}

/// Fiat loan details model
@freezed
class FiatLoanDetails with _$FiatLoanDetails {
  const factory FiatLoanDetails({
    required String bankName,
    required String bankAddress,
    required String bankCountry,
    required String purposeOfRemittance,
    required String fullName,
    required String address,
    required String city,
    required String postCode,
    required String country,
    String? comments,
    IbanTransferDetails? ibanTransferDetails,
    SwiftTransferDetails? swiftTransferDetails,
  }) = _FiatLoanDetails;

  factory FiatLoanDetails.fromJson(Map<String, dynamic> json) =>
      _$FiatLoanDetailsFromJson(json);
}

/// IBAN transfer details model
@freezed
class IbanTransferDetails with _$IbanTransferDetails {
  const factory IbanTransferDetails({
    required String iban,
    String? bic,
  }) = _IbanTransferDetails;

  factory IbanTransferDetails.fromJson(Map<String, dynamic> json) =>
      _$IbanTransferDetailsFromJson(json);
}

/// Swift transfer details model
@freezed
class SwiftTransferDetails with _$SwiftTransferDetails {
  const factory SwiftTransferDetails({
    required String swiftOrBic,
    required String accountNumber,
  }) = _SwiftTransferDetails;

  factory SwiftTransferDetails.fromJson(Map<String, dynamic> json) =>
      _$SwiftTransferDetailsFromJson(json);
}

/// Loan type
@freezed
class TimelineEvent with _$TimelineEvent {
  const factory TimelineEvent({
    required DateTime date,
    required ContractStatus event,
    String? txid,
  }) = _TimelineEvent;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);
}

/// Loan asset type
@JsonEnum(fieldRename: FieldRename.snake)
enum LoanAsset {
  btc,
  usd,
  eur,
  chf,
  usdcPol,
  usdtPol,
  usdcEth,
  usdtEth,
  usdcStrk,
  usdtStrk,
  usdcSol,
  usdtSol,
  usdtLiquid,
}

/// Loan offer status
@JsonEnum(fieldRename: FieldRename.pascal)
enum LoanOfferStatus {
  available,
  unavailable,
  deleted,
}

/// Contract status
@JsonEnum(fieldRename: FieldRename.pascal)
enum ContractStatus {
  requested,
  renewalRequested,
  approved,
  collateralSeen,
  collateralConfirmed,
  principalGiven,
  repaymentProvided,
  repaymentConfirmed,
  undercollateralized,
  defaulted,
  closing,
  closed,
  extended,
  rejected,
  cancelled,
  requestExpired,
  approvalExpired,
  disputeBorrowerStarted,
  disputeLenderStarted,
  disputeBorrowerResolved,
  disputeLenderResolved,
}

/// Liquidation status
@JsonEnum(fieldRename: FieldRename.pascal)
enum LiquidationStatus {
  healthy,
  firstMarginCall,
  secondMarginCall,
  liquidated,
}

/// Transaction type
@JsonEnum(fieldRename: FieldRename.pascal)
enum LendasatTransactionType {
  funding,
  dispute,
  principalGiven,
  principalRepaid,
  liquidation,
  claimCollateral,
}

/// Loan type
@JsonEnum(fieldRename: FieldRename.pascal)
enum LoanType {
  stablecoin,
  fiat,
  card,
}
