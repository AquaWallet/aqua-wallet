import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/data/provider/lwk_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/providers/transaction_fee_structure_provider.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:ui_components/ui_components.dart';

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

    final txnState = ref.watch(sendAssetTxnProvider(arg));
    // NOTE: If the transaction is complete, return the cached fee options
    // Recalculating the fee options after causes it to fail.
    if (txnState.hasValue &&
        txnState.value?.mapOrNull(complete: (_) => true) == true) {
      if (state.hasValue) {
        return state.value!;
      }
      return [];
    }

    final txn = await ref.watch(sendAssetTxnProvider(arg).future);
    final input = await ref.watch(sendAssetInputStateProvider(arg).future);

    final gdkTransaction = txn.mapOrNull(
      created: (e) => e.tx.mapOrNull(gdkTx: (t) => t.gdkTx),
    );

    if (arg.asset.isLiquid || arg.asset.isAnyUsdt) {
      final items = <LiquidFeeModel>[];

      final isUsdtAssetEnabled = ref.read(manageAssetsProvider).isUsdtEnabled;
      final isTaxiDisabled = ref.read(sideswapTaxiProvider).hasError;

      final liquidFeeOption = await _getLiquidFeeOption(
        gdkTransaction,
        unit: input.inputUnit,
        currency: input.rate.currency,
        isTaxiAvailable: !isTaxiDisabled,
      );
      items.add(liquidFeeOption);

      // Only add USDt taxi fee option for USDT sends (not for L-BTC)
      if (arg.asset.isAnyUsdt) {
        final liquidTaxiFeeOption = await _getLiquidTaxiFeeOption(
          input,
          isUsdtAssetEnabled: isUsdtAssetEnabled,
          isTaxiDisabled: isTaxiDisabled,
        );
        if (liquidTaxiFeeOption != null) {
          items.add(liquidTaxiFeeOption);
        }
      }

      final options = items.map(SendAssetFeeOptionModel.liquid).toList();
      if (options.isEmpty) {
        throw FeeOptionsNotFoundError();
      }

      final canPayFees = options.any((option) => option.maybeMap(
            liquid: (op) => op.fee.isEnabled && op.fee.availableForFeePayment,
            orElse: () => false,
          ));
      if (!canPayFees) {
        throw InsufficientBalanceError();
      }

      return options;
    }

    if (arg.asset.isBTC) {
      final options = await _getBitcoinFeeOptions(
        gdkTransaction,
        currency: input.rate.currency,
      );
      return options.isNotEmpty ? options : throw FeeOptionsNotFoundError();
    }

    return [];
  }

  Future<List<SendAssetFeeOptionModel>> _getBitcoinFeeOptions(
    GdkNewTransactionReply? gdkTransaction, {
    required FiatCurrency currency,
  }) async {
    if (gdkTransaction == null) {
      throw FeeTransactionNotFoundError();
    }

    final transactionVsize = gdkTransaction.transactionVsize;
    if (transactionVsize == null) {
      throw TransactionSizeNotFoundError();
    }

    final feeRatesByPriority = await ref.read(onChainFeeProvider.future);
    if (feeRatesByPriority.isEmpty) {
      throw FeeOptionsNotFoundError();
    }

    final rates = ref.read(fiatRatesProvider).valueOrNull ?? [];
    final rate =
        rates.firstWhereOrNull((e) => e.code == currency.value)?.rate ?? 0;
    final balance = await ref.read(balanceProvider).getBalance(arg.asset);

    final options = feeRatesByPriority.entries
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
                DecimalExt.fromDouble(rate),
              )
              .toDouble();
          final canPayThisFee = balance >= feeSatsByTxnSize;
          if (!canPayThisFee) {
            return null;
          }

          final feeFiatValue = ref.watch(fiatProvider).formatFiat(
                DecimalExt.fromDouble(feeFiat),
                currency.value,
              );
          final feeFiatDisplay = '≈ $feeFiatValue';
          final feeRateDisplay = feeRate % 1 == 0
              ? feeRate.toStringAsFixed(0)
              : feeRate.toStringAsFixed(1);

          return switch (e.key) {
            TransactionPriority.high => BitcoinFeeModel.high(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
                feeFiatDisplay: feeFiatDisplay,
                feeRateDisplay: feeRateDisplay,
              ),
            TransactionPriority.medium => BitcoinFeeModel.medium(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
                feeFiatDisplay: feeFiatDisplay,
                feeRateDisplay: feeRateDisplay,
              ),
            TransactionPriority.low => BitcoinFeeModel.low(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
                feeFiatDisplay: feeFiatDisplay,
                feeRateDisplay: feeRateDisplay,
              ),
            TransactionPriority.min => BitcoinFeeModel.min(
                feeSats: feeSats,
                feeFiat: feeFiat,
                feeRate: feeRate,
                feeFiatDisplay: feeFiatDisplay,
                feeRateDisplay: feeRateDisplay,
              ),
          };
        })
        .nonNulls
        .map(SendAssetFeeOptionModel.bitcoin)
        .toList();

    //NOTE - Fee options are available but the user has insufficient balance
    if (feeRatesByPriority.entries.isNotEmpty && options.isEmpty) {
      throw InsufficientBalanceError();
    }

    return options;
  }

  Future<LiquidFeeModel> _getLiquidFeeOption(
    GdkNewTransactionReply? gdkTransaction, {
    required AquaAssetInputUnit unit,
    required FiatCurrency currency,
    required bool isTaxiAvailable,
  }) async {
    // NOTE: Don't throw the errors if Taxi can be used for fee payment OR when the transaction fee is loading
    final transactionFee =
        gdkTransaction?.fee ?? kEstimatedLiquidSendNetworkFee.toInt();
    final isFeeAvailable = gdkTransaction?.error?.isEmpty ?? true;

    if (!isTaxiAvailable && gdkTransaction == null) {
      throw FeeTransactionNotFoundError();
    }

    if (!isTaxiAvailable && !isFeeAvailable) {
      throw FeeNotFoundError();
    }

    final lbtcAsset = Asset.lbtc();
    final lbtcFiatFeeDisplay = ref.read(formatProvider).formatAssetAmount(
          asset: lbtcAsset,
          amount: transactionFee,
          displayUnitOverride: SupportedDisplayUnits.fromAssetInputUnit(unit),
        );

    final fiatRates =
        ref.read(fiatRatesProvider).unwrapPrevious().valueOrNull ?? [];
    final rate =
        fiatRates.firstWhereOrNull((e) => e.code == currency.value)?.rate;
    final amount = isFeeAvailable
        ? rate != null
            ? transactionFee / (satsPerBtc / rate)
            : -1.0
        : 0.0;
    final fiatFeeAmount =
        ref.read(fiatProvider).formatSatsToFiatWithRateDisplay(
              asset: Asset.lbtc(),
              satoshi: transactionFee,
              rate: DecimalExt.fromDouble(rate ?? 0),
              currencyCode: currency.value,
            );

    final balance = await ref.read(balanceProvider).getBalance(lbtcAsset);
    final canPayLbtcFee = isFeeAvailable ? balance >= transactionFee : false;

    return LiquidFeeModel.lbtc(
      feeSats: transactionFee,
      feeFiat: amount,
      fiatFeeDisplay: '≈ $fiatFeeAmount',
      feeDisplay: lbtcFiatFeeDisplay,
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
      // TODO - This is a temporary fix to prevent the taxi fee option from being shown when the user is sending all funds.
      // Remove this once this is fixed.
      if (input.isSendAllFunds) {
        return null;
      }

      final usdtAsset = ref.read(manageAssetsProvider).liquidUsdtAsset;
      final usdtBalance = await ref.read(balanceProvider).getBalance(usdtAsset);
      //NOTE - Taxi fee estimate crashes if invoked with zero USDt balance
      final taxiFeeEstimate = usdtBalance > 0
          ? await ref.read(estimatedTaxiFeeUsdtProvider((
              input.amount,
              input.isSendAllFunds,
            )).future)
          : 0;

      final currency = input.rate.currency;
      final taxiFiatFeeDisplay =
          ref.read(amountInputServiceProvider).formatUsdtAmount(
                amountInSats: taxiFeeEstimate,
                asset: usdtAsset,
                targetCurrency: currency,
                currencyFormat: currency.format,
                withSymbol: true,
              );

      final canPayUsdtFee = usdtBalance >= taxiFeeEstimate;

      // NOTE: The fee is paid with LBTC by default. The taxi option is only
      // available if the asset being sent is a USDT
      final isLwkLoggedIn = await ref.read(lwkProvider).verifyInitialized();
      final usdtFeeEnabled =
          input.asset.isAnyUsdt && canPayUsdtFee && isLwkLoggedIn;

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
