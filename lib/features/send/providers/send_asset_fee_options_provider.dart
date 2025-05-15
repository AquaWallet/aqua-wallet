import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.send);

final sendAssetFeeOptionsProvider = AutoDisposeAsyncNotifierProviderFamily<
    SendAssetFeeOptionsNotifier,
    List<SendAssetFeeOptionModel>,
    SendAssetArguments>(SendAssetFeeOptionsNotifier.new);

class SendAssetFeeOptionsNotifier extends AutoDisposeFamilyAsyncNotifier<
    List<SendAssetFeeOptionModel>, SendAssetArguments> {
  @override
  FutureOr<List<SendAssetFeeOptionModel>> build(SendAssetArguments arg) async {
    if (state.hasError) {
      state = const AsyncLoading();
    }
    final txn = await ref.watch(sendAssetTxnProvider(arg).future);
    final input = await ref.read(sendAssetInputStateProvider(arg).future);

    final gdkTransaction = txn.mapOrNull(
      created: (e) => e.tx.mapOrNull(gdkTx: (t) => t.gdkTx),
    );

    if (arg.asset.isLiquid || arg.asset.isAnyUsdt) {
      final items = <LiquidFeeModel>[];

      final isUsdtAssetEnabled = ref.read(manageAssetsProvider).isUsdtEnabled;
      final isTaxiDisabled = ref.read(sideswapTaxiProvider).hasError;

      final liquidFeeOption = await _getLiquidFeeOption(
        gdkTransaction,
        isTaxiAvailable: !isTaxiDisabled,
      );
      items.add(liquidFeeOption);

      final liquidTaxiFeeOption = await _getLiquidTaxiFeeOption(
        input,
        isUsdtAssetEnabled: isUsdtAssetEnabled,
        isTaxiDisabled: isTaxiDisabled,
      );
      if (liquidTaxiFeeOption != null) {
        items.add(liquidTaxiFeeOption);
      }

      return items.map(SendAssetFeeOptionModel.liquid).toList();
    }

    if (arg.asset.isBTC) {
      return _getBitcoinFeeOptions(gdkTransaction);
    }

    return [];
  }

  Future<List<SendAssetFeeOptionModel>> _getBitcoinFeeOptions(
    GdkNewTransactionReply? gdkTransaction,
  ) async {
    if (gdkTransaction == null) {
      throw FeeTransactionNotFoundError();
    }

    final transactionVsize = gdkTransaction.transactionVsize;
    if (transactionVsize == null) {
      throw TransactionSizeNotFoundError();
    }

    final refCurrency = ref.read(prefsProvider).referenceCurrency;
    final rates = await ref.read(fiatRatesProvider.future).onError((e, st) {
      _logger.error('Error fetching fiat rates', e, st);
      return [];
    });
    final fiatRate =
        rates.firstWhereOrNull((e) => e.code == refCurrency)?.rate ?? 0;
    final feeRatesByPriority = await ref.read(onChainFeeProvider.future);

    return feeRatesByPriority.entries
        // Standard Fee goes first
        .sorted((e, _) => e.key == TransactionPriority.medium ? -1 : 1)
        .map((e) {
          final feeRate = e.value;
          final feeSats = (kVbPerKb * feeRate).toInt();
          final feeSatsByTxnSize = (feeRate * transactionVsize).toInt();
          final feeFiat = ref
              .read(fiatProvider)
              .satoshiToFiat(
                arg.asset,
                feeSatsByTxnSize,
                DecimalExt.fromDouble(fiatRate),
              )
              .toDouble();

          return switch (e.key) {
            TransactionPriority.high => BitcoinFeeModel.high(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
              ),
            TransactionPriority.medium => BitcoinFeeModel.medium(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
              ),
            TransactionPriority.low => BitcoinFeeModel.low(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
              ),
            TransactionPriority.min => BitcoinFeeModel.min(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
              ),
          };
        })
        .map(SendAssetFeeOptionModel.bitcoin)
        .toList();
  }

  Future<LiquidFeeModel> _getLiquidFeeOption(
    GdkNewTransactionReply? gdkTransaction, {
    required bool isTaxiAvailable,
  }) async {
    // NOTE: Don't throw the errors if Taxi can be used for fee payment
    final transactionFee = gdkTransaction?.fee;
    final isFeeAvailable = transactionFee != null;

    if (!isTaxiAvailable && gdkTransaction == null) {
      throw FeeTransactionNotFoundError();
    }

    if (!isTaxiAvailable && !isFeeAvailable) {
      throw FeeNotFoundError();
    }

    final feeRatePerVb = await ref.read(liquidFeeRateProvider.future);
    final fiatRates = await ref.read(fiatRatesProvider.future).onError((e, st) {
      _logger.error('Error fetching fiat rates', e, st);
      return [];
    });
    final refCurrency = ref.read(prefsProvider).referenceCurrency;
    final rate = fiatRates.firstWhereOrNull((e) => e.code == refCurrency)?.rate;
    final feeFiatAmount = isFeeAvailable
        ? rate != null
            ? transactionFee / (satsPerBtc / rate)
            : -1.0
        : 0.0;
    final balance = await ref.read(balanceProvider).getBalance(arg.asset);
    final canPayLbtcFee = isFeeAvailable ? balance >= transactionFee : false;
    final lbtcFiatFeeDisplay = feeFiatAmount >= 0
        ? '≈ $refCurrency ${feeFiatAmount.toStringAsFixed(2)}'
        : '';

    return LiquidFeeModel.lbtc(
      feeSats: transactionFee ?? 0,
      feeFiat: feeFiatAmount,
      fiatCurrency: refCurrency ?? '',
      fiatFeeDisplay: lbtcFiatFeeDisplay,
      satsPerByte: feeRatePerVb,
      isEnabled: canPayLbtcFee,
      availableForFeePayment: canPayLbtcFee,
    );
  }

  Future<LiquidFeeModel?> _getLiquidTaxiFeeOption(
    SendAssetInputState input, {
    required bool isUsdtAssetEnabled,
    required bool isTaxiDisabled,
  }) async {
    if (isUsdtAssetEnabled && !isTaxiDisabled) {
      final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
      final usdtBalance = await ref.read(balanceProvider).getBalance(usdtAsset);
      //NOTE - Taxi fee estimate crashes if invoked with zero USDt balance
      final taxiFeeEstimate = usdtBalance > 0
          ? await ref.read(estimatedTaxiFeeUsdtProvider((
              input.amount,
              input.isSendAllFunds,
              // TODO: isLowball hardcoded true as a temporary hack. Need to revisit when taxi fee estimate is using DiscountCT values
              true,
            )).future)
          : 0;
      final taxiFeeFiat = ref.read(formatterProvider).formatAssetAmountDirect(
            amount: taxiFeeEstimate,
            precision: usdtAsset.precision,
            roundingOverride: kUsdtDisplayPrecision,
            removeTrailingZeros: false,
          );
      final taxiFiatFeeDisplay = '~$taxiFeeFiat ${usdtAsset.ticker}';

      final canPayUsdtFee = usdtBalance >= taxiFeeEstimate;

      // NOTE: The fee is paid with LBTC by default. The taxi option is only
      // available if the asset being sent is a USDT
      final usdtFeeEnabled = input.asset.isAnyUsdt && canPayUsdtFee;

      return LiquidFeeModel.usdt(
        feeAmount: taxiFeeEstimate,
        feeCurrency: usdtAsset.ticker,
        feeDisplay: taxiFiatFeeDisplay,
        isEnabled: usdtFeeEnabled,
        availableForFeePayment: canPayUsdtFee,
      );
    }
    return null;
  }
}
