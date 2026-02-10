import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base interface for lending services
abstract class LendingService {
  /// Initialize the lending service
  Future<void> initialize();

  /// Get all available loan offers
  Future<List<LoanOffer>> getLoanOffers();

  /// Get all contracts for the current user
  Future<List<LoanContract>> getContracts();

  /// Request a new loan contract
  Future<LoanContract> requestContract(ContractRequest request);

  /// Get a specific contract by ID
  Future<LoanContract> getContract(String contractId);

  /// Get a PSBT for claiming collateral
  Future<CollateralPsbt> getClaimCollateralPsbt(String contractId, int feeRate);

  /// Post a signed transaction for claiming collateral
  Future<String> postClaimTx(String contractId, String signedTx);

  /// Mark a contract as repaid for the lender to be approved
  Future<void> markContractAsRepaid(String contractId, String transactionId);

  /// Get the current API key if required by the service
  Future<String?> getApiKey();

  /// Set the API key if required by the service
  Future<void> setApiKey(String apiKey);

  /// Clear the API key if required by the service
  Future<void> clearApiKey();

  /// Check if the service requires an API key
  bool get requiresApiKey;

  /// Get the service name
  String get serviceName;

  /// Get the service description
  String get serviceDescription;

  /// Get the service icon path
  String get serviceIconPath;

  /// Get the service website URL
  String get serviceWebsiteUrl;

  /// Get the service terms of service URL
  String get serviceTermsUrl;

  /// Get the service privacy policy URL
  String get servicePrivacyUrl;

  /// Get the service support URL
  String get serviceSupportUrl;

  /// Get the service KYC URL if required
  String? get serviceKycUrl;

  /// Check if the service requires KYC
  bool get requiresKyc;
}

final lendingServiceProvider = Provider<LendingService>((ref) {
  throw UnimplementedError(
      'No LendingService implementation has been provided');
});
