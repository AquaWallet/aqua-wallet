import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ui_components/ui_components.dart' hide AssetIds;

part 'send_asset_input_state.freezed.dart';

@freezed
class SendAssetInputState with _$SendAssetInputState {
  const factory SendAssetInputState({
    required Asset asset,
    List<Asset>? ambiguousAssets,
    SwapPair? swapPair,
    String? addressFieldText,
    String? clipboardAddress,
    String? scannedQrCode,
    String? scannedText,
    String? amountFieldText,
    @Default(0) int amount,

    /// The amount that should be sent in the transaction, which may differ from
    /// the user-entered amount due to fee adjustments from services like swaps.
    /// When null, the original `amount` is used.
    int? adjustedAmountToSend,
    String? displayConversionAmount,
    String? usdtCryptoAmount,
    required ExchangeRate rate,
    @Default(AquaAssetInputUnit.crypto) AquaAssetInputUnit inputUnit,
    @Default(AquaAssetInputType.crypto) AquaAssetInputType inputType,
    @Default(false) bool isSendAllFunds,
    LNURLParseResult? lnurlData,
    InsufficientFundsType? insufficientFundsType,
    @Default(0) int balanceInSats,
    @Default('-') String balanceDisplay,
    @Default('-') String balanceFiatDisplay,
    @Default(FeeAsset.lbtc) FeeAsset feeAsset,
    SendAssetFeeOptionModel? fee,
    @Default(SendTransactionType.send) SendTransactionType transactionType,
    String? externalSweepPrivKey,
    String? note,
    String? serviceOrderId,
    @Default(false) bool isBoltzToBoltzSwap,
  }) = _SendAssetInputState;
}

extension SendAssetInputStateX on SendAssetInputState {
  /// Calculates the appropriate decimal precision for amount input
  /// based on input type, asset, display unit, and currency.
  int get precision {
    if (inputType == AquaAssetInputType.crypto) {
      if (asset.isBTC || asset.isLBTC || asset.isLightning) {
        return SupportedDisplayUnits.fromAssetInputUnit(inputUnit)
            .getDisplayPrecision(asset);
      }
      return asset.precision;
    } else {
      return rate.currency.format.decimalPlaces;
    }
  }

  bool get isAmbiguousAssets =>
      (ambiguousAssets?.isNotEmpty ?? false) && ambiguousAssets!.length > 1;

  bool get isAmountEditable {
    if (isBoltzToBoltzSwap) {
      return false;
    }
    if (asset.isLightning) {
      return !isLightningFromInvoice && !isLnurlPayFixedAmount;
    }

    final bip21Data = Bip21Decoder.decodeOrNull(addressFieldText);
    final hasBip21Amount = bip21Data?['amount'] != null;
    return !hasBip21Amount;
  }

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

  bool get isCryptoAmountInput => inputType == AquaAssetInputType.crypto;

  bool get isFiatAmountInput => inputType == AquaAssetInputType.fiat;

  bool get isLiquidFeeAsset => feeAsset == FeeAsset.lbtc;

  bool get isUsdtFeeAsset => feeAsset == FeeAsset.tetherUsdt;

  bool get isSatsUnit => inputUnit == AquaAssetInputUnit.sats;

  SendFlowStep get initialStep {
    // externalSweepPrivKey
    if (externalSweepPrivKey != null) {
      return SendFlowStep.review;
    }

    if (isAddressFieldEmpty && amount == 0) {
      return SendFlowStep.address;
    } else if (amount == 0) {
      if (isAmbiguousAssets) {
        return SendFlowStep.network;
      }
      return SendFlowStep.amount;
    } else {
      return SendFlowStep.review;
    }
  }

  bool get isNonFiatAsset => asset.shouldShowConversionOnSend;

  bool get isFiatDisplayAmountAvailable =>
      displayConversionAmount != null && displayConversionAmount!.isNotEmpty;

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
