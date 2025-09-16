import 'dart:async';

import 'package:coin_cz/features/private_integrations/private_integrations.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';

final topUpInputStateProvider =
    AutoDisposeAsyncNotifierProvider<TopUpInputStateNotifier, TopUpInputState>(
        TopUpInputStateNotifier.new);

class TopUpInputStateNotifier
    extends AutoDisposeAsyncNotifier<TopUpInputState> {
  @override
  FutureOr<TopUpInputState> build() async {
    final assets = [
      ...?ref.watch(assetsProvider).valueOrNull?.where((e) => e.isInternal)
    ];
    final asset = assets.firstWhere((e) => e.isBTC);
    final balanceInSats = await ref.read(balanceProvider).getBalance(asset);
    return TopUpInputState(
      asset: asset,
      availableAssets: assets,
      balanceInSats: balanceInSats,
    );
  }

  Future<void> selectAsset(Asset asset) async {
    final balanceInSats = await ref.read(balanceProvider).getBalance(asset);
    state = AsyncValue.data(state.value!.copyWith(
      asset: asset,
      amount: 0,
      amountFieldText: null,
      amountInUsd: null,
      balanceInSats: balanceInSats,
      amountInputType: CryptoAmountInputType.crypto,
    ));
  }

  Future<void> setAmount(String text) async {
    // Use the currently selected amount input type to determine the type of
    // conversion to apply
    final asset = state.value!.asset;
    final isFiatInput = state.value!.isFiatAmountInput;
    final amountSats =
        await ref.read(amountInputMutationsProvider).getConvertedAmountSats(
              text: text,
              asset: asset,
              isFiatInput: isFiatInput,
            );

    // Update converted amount with each amount update
    final amountInUsd = asset.isAnyUsdt || isFiatInput
        ? text
        : await ref.read(amountInputMutationsProvider).getConvertedAmount(
              asset: asset,
              amountSats: amountSats,
              isFiatAmountInput: isFiatInput,
              withSymbol: false,
            );

    state = AsyncValue.data(state.value!.copyWith(
      amount: amountSats,
      amountFieldText: text,
      amountInUsd: amountInUsd,
    ));
  }

  void setInputType(CryptoAmountInputType type) {
    state = AsyncValue.data(state.value!.copyWith(
      amount: 0,
      amountFieldText: null,
      amountInUsd: null,
      amountInputType: type,
    ));
  }
}
