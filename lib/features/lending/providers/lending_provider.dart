import 'package:aqua/features/lending/models/models.dart';
import 'package:aqua/features/lending/services/lending_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua/features/lending/providers/selected_offer_provider.dart';

class LendingNotifier extends AutoDisposeAsyncNotifier<LendingState> {
  late final LendingService _service;

  @override
  Future<LendingState> build() async {
    _service = ref.watch(lendingServiceProvider);

    // Watch selectedOfferIdProvider to update selectedOffer when it changes
    ref.listen<String?>(selectedOfferIdProvider, (_, offerId) {
      _updateSelectedOffer(offerId);
    });

    // Watch self to update selectedOffer when offers list changes
    ref.listenSelf((previous, next) {
      final previousOffers = previous?.value?.offers;
      final nextOffers = next.value?.offers;
      if (previousOffers != nextOffers) {
        final offerId = ref.read(selectedOfferIdProvider);
        _updateSelectedOffer(offerId);
      }
    });

    // Return initial state - selectedOffer will be updated via listeners
    return const LendingState();
  }

  void _updateSelectedOffer(String? offerId) {
    if (state.value == null) return; // Not yet initialized

    final currentOffers = state.value!.offers.asData?.value;
    LoanOffer? offer;

    if (offerId != null && currentOffers != null) {
      try {
        offer = currentOffers.firstWhere((o) => o.id == offerId);
        state = AsyncValue.data(
            state.value!.copyWith(selectedOffer: AsyncValue.data(offer)));
      } catch (e) {
        // Offer not found in the current list
        state = AsyncValue.data(
            state.value!.copyWith(selectedOffer: const AsyncValue.data(null)));
      }
    } else {
      state = AsyncValue.data(
          state.value!.copyWith(selectedOffer: const AsyncValue.data(null)));
    }
  }

  Future<void> initialize() async {
    final currentStateValue = state.value;
    if (currentStateValue?.isInitialized ?? false) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _service.initialize();
      final apiKeyVal = await _service.getApiKey();

      if (_service.requiresApiKey && apiKeyVal == null) {
        return const LendingState(
          apiKey: AsyncValue.data(null),
          offers: AsyncValue.data([]),
          contracts: AsyncValue.data([]),
          isInitialized: true,
          selectedOffer: AsyncValue.data(null),
        );
      }

      final offersVal = await _service.getLoanOffers();
      final contractsVal = await _service.getContracts();

      // Get the selected offer after fetching offers
      final offerId = ref.read(selectedOfferIdProvider);
      LoanOffer? selectedOfferVal;
      if (offerId != null) {
        try {
          selectedOfferVal = offersVal.firstWhere((o) => o.id == offerId);
        } catch (e) {
          selectedOfferVal = null;
        }
      }

      return LendingState(
        apiKey: AsyncValue.data(apiKeyVal),
        offers: AsyncValue.data(offersVal),
        contracts: AsyncValue.data(contractsVal),
        isInitialized: true,
        selectedOffer: AsyncValue.data(selectedOfferVal),
      );
    });
  }

  Future<void> setApiKey(String apiKey) async {
    state = await AsyncValue.guard(() async {
      final currentStateValue = state.value!;
      await _service.setApiKey(apiKey);

      final newApiKey = await _service.getApiKey();
      final offers = await _service.getLoanOffers();
      final contracts = await _service.getContracts();

      // Get the selected offer after fetching offers
      final offerId = ref.read(selectedOfferIdProvider);
      LoanOffer? selectedOfferVal;
      if (offerId != null) {
        try {
          selectedOfferVal = offers.firstWhere((o) => o.id == offerId);
        } catch (e) {
          selectedOfferVal = null;
        }
      }

      return currentStateValue.copyWith(
        apiKey: AsyncValue.data(newApiKey),
        offers: AsyncValue.data(offers),
        contracts: AsyncValue.data(contracts),
        selectedOffer: AsyncValue.data(selectedOfferVal),
      );
    });
  }

  Future<void> clearApiKey() async {
    state = await AsyncValue.guard(() async {
      final currentStateValue = state.value!;
      await _service.clearApiKey();

      final newApiKey = await _service.getApiKey();
      final offers = await _service.getLoanOffers();
      final contracts = await _service.getContracts();

      // When API key is cleared, selected offer should also be cleared
      return currentStateValue.copyWith(
        apiKey: AsyncValue.data(newApiKey),
        offers: AsyncValue.data(offers),
        contracts: AsyncValue.data(contracts),
        selectedOffer: const AsyncValue.data(null),
      );
    });
  }

  Future<void> refreshAll() async {
    state = await AsyncValue.guard(() async {
      final currentStateValue = state.value!;

      final apiKey = await _service.getApiKey();
      final offers = await _service.getLoanOffers();
      final contracts = await _service.getContracts();

      // Get the selected offer after fetching offers
      final offerId = ref.read(selectedOfferIdProvider);
      LoanOffer? selectedOfferVal;
      if (offerId != null) {
        try {
          selectedOfferVal = offers.firstWhere((o) => o.id == offerId);
        } catch (e) {
          selectedOfferVal = null;
        }
      }

      return currentStateValue.copyWith(
        apiKey: AsyncValue.data(apiKey),
        offers: AsyncValue.data(offers),
        contracts: AsyncValue.data(contracts),
        selectedOffer: AsyncValue.data(selectedOfferVal),
      );
    });
  }

  Future<LoanContract> requestContract(ContractRequest request) async {
    final contract = await _service.requestContract(request);
    await refreshAll(); // This will also update selectedOffer if offers list changes
    return contract;
  }

  Future<LoanContract> getContract(String contractId) async {
    final contract = await _service.getContract(contractId);
    await refreshAll();
    return contract;
  }

  Future<CollateralPsbt> getClaimCollateralPsbt(
      String contractId, int feeRate) async {
    return await _service.getClaimCollateralPsbt(contractId, feeRate);
  }

  Future<String> postClaimTx(String contractId, String signedTx) async {
    final txid = await _service.postClaimTx(contractId, signedTx);
    await refreshAll();
    return txid;
  }

  Future<void> markAsRepaid(String contractId, String transactionId) async {
    await _service.markContractAsRepaid(contractId, transactionId);
    await refreshAll();
  }

  Future<String> signWithdrawalTransaction(
      String contractId, int feeRate) async {
    // ignore: unused_local_variable
    final collateralPsbt =
        await _service.getClaimCollateralPsbt(contractId, feeRate);
    // TODO: sign collateralPsbt.psbt
    const tx = "tx"; // wallet.sign();

    // we provide a convenience method to publish the transaction through our API
    final txid = await _service.postClaimTx(contractId, tx);

    await refreshAll();
    return txid;
  }

  // Service property getters
  bool get requiresApiKey => _service.requiresApiKey;
  String get serviceName => _service.serviceName;
  String get serviceDescription => _service.serviceDescription;
  String get serviceIconPath => _service.serviceIconPath;
  String get serviceWebsiteUrl => _service.serviceWebsiteUrl;
  String get serviceTermsUrl => _service.serviceTermsUrl;
  String get servicePrivacyUrl => _service.servicePrivacyUrl;
  String get serviceSupportUrl => _service.serviceSupportUrl;
  String? get serviceKycUrl => _service.serviceKycUrl;
  bool get requiresKyc => _service.requiresKyc;
}

final lendingProvider =
    AutoDisposeAsyncNotifierProvider<LendingNotifier, LendingState>(
        LendingNotifier.new);
