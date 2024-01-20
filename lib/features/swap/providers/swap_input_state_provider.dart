import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

final sideswapInputStateProvider = AutoDisposeStateNotifierProvider<
    SideswapInputStateNotifier, SideswapInputState>((ref) {
  final assets = ref.watch(swapAssetsProvider).assets;
  final deliverAsset = assets.firstWhereOrNull((e) => e.isLBTC);
  final receiveAsset = assets.firstWhereOrNull((e) => e.isUSDt);
  final deliverAssetBalance = deliverAsset != null
      ? ref
          .read(formatterProvider)
          .formatAssetAmountFromAsset(asset: deliverAsset)
      : '';
  final receiveAssetBalance = receiveAsset != null
      ? ref
          .read(formatterProvider)
          .formatAssetAmountFromAsset(asset: receiveAsset)
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
    state = state.copyWith(
      deliverAmount: '',
      deliverAmountSatoshi: 0,
      receiveAmount: '',
      receiveAmountSatoshi: 0,
      deliverAsset: asset,
      deliverAssetBalance:
          ref.watch(formatterProvider).formatAssetAmountFromAsset(asset: asset),
    );
  }

  void setReceiveAsset(Asset asset) {
    state = state.copyWith(
      deliverAmount: '',
      deliverAmountSatoshi: 0,
      receiveAmount: '',
      receiveAmountSatoshi: 0,
      receiveAsset: asset,
      receiveAssetBalance:
          ref.watch(formatterProvider).formatAssetAmountFromAsset(asset: asset),
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
}
