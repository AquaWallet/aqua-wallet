import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

final sideswapInputStateProvider = AutoDisposeStateNotifierProvider<
    SideswapInputStateNotifier, SideswapInputState>((ref) {
  final assets = ref.watch(swapAssetsProvider).assets;
  final deliverAsset = assets.firstWhereOrNull((e) => e.isLBTC);
  final receiveAsset = ref.read(manageAssetsProvider).isUsdtEnabled
      ? assets.firstWhereOrNull((e) => e.isUSDt)
      : assets.firstWhereOrNull((e) => e.isBTC);
  final deliverAssetBalance = deliverAsset != null
      ? ref.read(formatterProvider).convertAssetAmountToDisplayUnit(
          amount: deliverAsset.amount, precision: deliverAsset.precision)
      : '';
  final receiveAssetBalance = receiveAsset != null
      ? ref.read(formatterProvider).convertAssetAmountToDisplayUnit(
          amount: receiveAsset.amount, precision: receiveAsset.precision)
      : '';

  final initialState = SideswapInputState(
    assets: assets,
    deliverAsset: deliverAsset,
    receiveAsset: receiveAsset,
    deliverAssetBalance: deliverAssetBalance,
    receiveAssetBalance: receiveAssetBalance,
  );

  return SideswapInputStateNotifier(ref, initialState);
});

class SideswapInputStateNotifier extends StateNotifier<SideswapInputState> {
  SideswapInputStateNotifier(
    this.ref,
    SideswapInputState initialState,
  ) : super(initialState);

  final AutoDisposeRef ref;

  void setDeliverAsset(Asset asset) {
    final swappableAssets = ref.read(swapAssetsProvider).swappableAssets(asset);
    if (state.receiveAsset != null &&
        !swappableAssets.contains(state.receiveAsset)) {
      setReceiveAsset(swappableAssets.first);
    }

    state = state.copyWith(
      deliverAmount: '',
      deliverAmountSatoshi: 0,
      receiveAmount: '',
      receiveAmountSatoshi: 0,
      deliverAsset: asset,
      deliverAssetBalance: ref
          .watch(formatterProvider)
          .convertAssetAmountToDisplayUnit(
              amount: asset.amount, precision: asset.precision),
    );
  }

  void setReceiveAsset(Asset asset) {
    state = state.copyWith(
      deliverAmount: '',
      deliverAmountSatoshi: 0,
      receiveAmount: '',
      receiveAmountSatoshi: 0,
      receiveAsset: asset,
      receiveAssetBalance: ref
          .watch(formatterProvider)
          .convertAssetAmountToDisplayUnit(
              amount: asset.amount, precision: asset.precision),
    );
  }

  void setDeliverAmount(String? value) {
    if (state.deliverAsset != null) {
      final satoshi = ref.read(formatterProvider).parseAssetAmountDirect(
            amount: value?.isNotEmpty ?? false ? value! : 0.toString(),
            precision: state.deliverAsset!.precision,
          );

      state = state.copyWith(
        deliverAmount: value ?? '',
        deliverAmountSatoshi: satoshi,
      );
    }
  }

  void setReceiveAmount(String? value) {
    if (state.receiveAsset != null) {
      final satoshi = ref.read(formatterProvider).parseAssetAmountDirect(
            amount: value?.isNotEmpty ?? false ? value! : 0.toString(),
            precision: state.receiveAsset!.precision,
          );

      state = state.copyWith(
        receiveAmount: value ?? '',
        receiveAmountSatoshi: satoshi,
      );
    }
  }

  void setUserInputSide(SwapUserInputSide side) {
    state = state.copyWith(
      userInputSide: side,
    );
  }

  void setMaxDeliverAmount() {
    if (state.deliverAsset != null) {
      setDeliverAmount(state.deliverAssetBalance);
    }
  }

  // NOTE: Only used for testing
  void setMinDeliverAmount() {
    final asset = state.deliverAsset;
    if (asset != null) {
      final status = ref.read(sideswapStatusStreamResultStateProvider);
      final serviceFee = state.isPegIn
          ? status?.serverFeePercentPegIn ?? 0.1
          : status?.serverFeePercentPegOut ?? 0.1;
      final minPegAmount = state.isPegIn
          ? ref.read(minPegInAmountWithFeeProvider)
          : ref.read(minPegOutAmountWithFeeProvider);
      final feeAmount = (minPegAmount * (serviceFee * 2) / 100).ceil();
      final minPegAmountWithFee = minPegAmount + feeAmount;
      final amount = ref.read(formatterProvider).formatAssetAmountDirect(
            amount: minPegAmountWithFee,
            precision: asset.precision,
          );
      setDeliverAmount(amount);
    }
  }

  void switchAssets() {
    final deliverAsset = state.deliverAsset;
    final receiveAsset = state.receiveAsset;

    setDeliverAsset(receiveAsset!);
    setReceiveAsset(deliverAsset!);
  }

  void switchInputType() {
    state = state.copyWith(
      isFiat: !state.isFiat,
    );
  }
}
