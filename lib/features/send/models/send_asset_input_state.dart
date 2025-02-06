import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_input_state.freezed.dart';

@freezed
class SendAssetInputState with _$SendAssetInputState {
  const factory SendAssetInputState({
    required Asset asset,
    SwapPair? swapPair,
    String? addressFieldText,
    String? clipboardAddress,
    String? scannedQrCode,
    String? amountFieldText,
    @Default(0) int amount,
    String? amountConversionDisplay,
    @Default(CryptoAmountInputType.crypto)
    CryptoAmountInputType amountInputType,
    @Default(false) bool isSendAllFunds,
    @Default(true) bool isAmountEditable,
    LNURLParseResult? lnurlData,
    InsufficientFundsType? insufficientFundsType,
    @Default(0) int balanceInSats,
    @Default('-') String balanceDisplay,
    @Default('-') String balanceFiatDisplay,
    @Default(FeeAsset.lbtc) FeeAsset feeAsset,
    SendAssetFeeOptionModel? fee,
    @Default(SendTransactionType.send) SendTransactionType transactionType,
    String? note,
  }) = _SendAssetInputState;
}

extension SendAssetInputStateX on SendAssetInputState {
  bool get isClipboardEmpty => clipboardAddress?.isEmpty ?? true;

  bool get isAddressFieldEmpty => addressFieldText?.isEmpty ?? true;

  bool get isAmountFieldEmpty => amountFieldText?.isEmpty ?? true;

  bool get isScannedQrCodeEmpty => scannedQrCode?.isEmpty ?? true;

  bool get isLnurl => lnurlData?.payParams != null;

  bool get isLightning => asset.isLightning;

  bool get isLightningFromInvoice =>
      asset.isLightning && lnurlData?.payParams == null;

  bool get isLnurlPayFixedAmount =>
      lnurlData?.payParams?.isFixedAmount ?? false;

  bool get isInsufficientFunds => insufficientFundsType != null;

  bool get isInsufficientFundsForFee =>
      insufficientFundsType == InsufficientFundsType.fee;

  bool get isInsufficientFundsForSendAmount =>
      insufficientFundsType == InsufficientFundsType.sendAmount;

  bool get isCryptoAmountInput =>
      amountInputType == CryptoAmountInputType.crypto;

  bool get isFiatAmountInput => amountInputType == CryptoAmountInputType.fiat;

  bool get isLiquidFeeAsset => feeAsset == FeeAsset.lbtc;

  bool get isUsdtFeeAsset => feeAsset == FeeAsset.tetherUsdt;

  SendFlowStep get initialStep {
    if (isAddressFieldEmpty && amount == 0) {
      return SendFlowStep.address;
    } else if (amount == 0) {
      return SendFlowStep.amount;
    } else {
      return SendFlowStep.review;
    }
  }

  bool get isNonFiatAsset => asset.shouldShowConversionOnSend;

  bool get isFiatDisplayAmountAvailable =>
      amountConversionDisplay != null && amountConversionDisplay!.isNotEmpty;

  bool get isTopUp => transactionType == SendTransactionType.topUp;

  TransactionDbModelType get transactionDbModelType {
    if (isTopUp) {
      return TransactionDbModelType.moonTopUp;
    }
    if (asset.isLightning) {
      return TransactionDbModelType.boltzSwap;
    }
    if (asset.isAltUsdt) {
      return TransactionDbModelType.sideshiftSwap;
    }
    return TransactionDbModelType.aquaSend;
  }

  String? get sendAssetId => switch (asset) {
        _ when (asset.id == AssetIds.btc) => null,
        _ when (asset.isAltUsdt) => AssetIds.getAssetId(
            AssetType.usdtliquid,
            LiquidNetworkEnumType.mainnet,
          ),
        _ when (asset.isLightning) => AssetIds.getAssetId(
            AssetType.lbtc,
            LiquidNetworkEnumType.mainnet,
          ),
        _ => asset.id,
      };

  int? get taxiFeeSats => fee?.mapOrNull(
        liquid: (value) => value.fee.mapOrNull(
          usdt: (value) => value.feeAmount,
        ),
      );
}
