import 'package:coin_cz/features/account/account.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'top_up_input_state.freezed.dart';

@freezed
class TopUpInputState with _$TopUpInputState {
  const factory TopUpInputState({
    required Asset asset,
    @Default([]) List<Asset> availableAssets,
    String? amountFieldText,
    @Default(0) int amount,
    String? amountInUsd,
    @Default(0) int balanceInSats,
    @Default(CryptoAmountInputType.crypto)
    CryptoAmountInputType amountInputType,
  }) = _TopUpInputState;
}

extension TopUpInputStateExt on TopUpInputState {
  bool get isAmountFieldEmpty => amountFieldText?.isEmpty ?? true;

  bool get isCryptoAmountInput =>
      amountInputType == CryptoAmountInputType.crypto;

  bool get isFiatAmountInput => amountInputType == CryptoAmountInputType.fiat;

  Currency get currency => asset.isUsdtLiquid ? Currency.usdt : Currency.btc;

  Blockchain get blockchain =>
      asset.isBTC ? Blockchain.bitcoin : Blockchain.liquid;
}
