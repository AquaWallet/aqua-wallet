import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetAmountPage extends HookConsumerWidget {
  const SendAssetAmountPage({
    super.key,
    required this.onContinuePressed,
    required this.arguments,
  });

  final VoidCallback onContinuePressed;
  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final provider = useMemoized(() => sendAssetInputStateProvider(arguments));
    final notifier = useMemoized(() => ref.read(provider.notifier));
    final input = ref.watch(provider).value!;
    final validationsProvider = useMemoized(() {
      return sendAssetAmountValidationProvider(arguments);
    });
    final error = ref.watch(validationsProvider).error as ExceptionLocalized?;
    final constraints =
        ref.watch(sendAssetAmountConstraintsProvider(arguments)).valueOrNull;
    final isValidAmount = ref.watch(validationsProvider).valueOrNull ?? false;
    final currency = ref.watch(exchangeRatesProvider.select(
      (p) => p.currentCurrency.currency.value,
    ));
    final isContinueButtonEnabled = useMemoized(
      () => error == null && isValidAmount,
      [error, isValidAmount],
    );
    final controller = useTextEditingController(text: input.amountFieldText);

    ref.listen(provider, (_, state) {
      controller.text = state.value?.amountFieldText ?? '';
    });

    final displayUnit = ref.watch(displayUnitsProvider
        .select((p) => p.getForcedDisplayUnit(input.asset)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //ANCHOR - Logo
          AssetIcon(
            assetId: input.asset.id,
            assetLogoUrl: input.asset.logoUrl,
            size: 60.0,
          ),
          const SizedBox(height: 20.0),

          //ANCHOR - Balance Amount & Symbol
          AssetCryptoAmount(
            forceVisible: true,
            forceDisplayUnit: displayUnit,
            amount: input.balanceInSats.toString(),
            asset: input.asset,
            style: context.textTheme.headlineLarge,
          ),
          const SizedBox(height: 14.0),

          //ANCHOR - Balance USD Equivalent
          if (input.asset.shouldShowConversionOnSend) ...[
            Container(
              decoration: BoxDecoration(
                color: context.colors.usdCenterPillBackgroundColor,
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
              child: AssetCryptoAmount(
                forceVisible: true,
                style: context.textTheme.titleMedium,
                amount: input.balanceFiatDisplay,
              ),
            ),
          ],
          const SizedBox(height: 40.0),

          //ANCHOR - Amount Input
          SendAssetAmountInput(
            controller: controller,
            symbol: input.isFiatAmountInput ? currency : input.asset.ticker,
            allowUsdToggle: input.asset.shouldAllowUsdToggleOnSend,
            precision: input.asset.precision,
            onChanged: (text) => notifier.updateAmountFieldText(text),
            disabled: !input.isAmountEditable,
            onCurrencyTypeToggle: () => notifier.setInputType(
              input.isFiatAmountInput
                  ? CryptoAmountInputType.crypto
                  : CryptoAmountInputType.fiat,
            ),
          ),

          const SizedBox(height: 2.0),

          //ANCHOR - Min/Max Range Panel
          if (input.asset.isAltUsdt) ...{
            const SizedBox(height: 16.0),
            USDtSwapMinMaxPanel(
              swapPair: SwapPair(
                from: SwapAssetExt.usdtLiquid,
                to: SwapAsset.fromAsset(input.asset),
              ),
            ),
          } else if (input.asset.isLightning &&
              input.isFiatDisplayAmountAvailable) ...{
            const SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                //ANCHOR - Fiat/Crypto Amount Conversion
                _ConvertedAmountLabel(input.amountConversionDisplay!),
              ],
            ),
            if (!input.isLnurlPayFixedAmount && constraints != null) ...[
              const SizedBox(height: 24.0),
              //ANCHOR - Lightning Amount Constraints
              _LightningAmountConstraintsLabel(constraints),
            ],
          } else ...{
            SizedBox(
              height: 60.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (error != null) ...{
                    //ANCHOR - Error Message
                    Text(
                      error.toLocalizedString(context),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.error,
                      ),
                    )
                  } else if (input.asset.shouldShowConversionOnSend &&
                      input.isFiatDisplayAmountAvailable) ...{
                    //ANCHOR - Conversion to fiat
                    _ConvertedAmountLabel(input.amountConversionDisplay!),
                  },

                  const Spacer(),

                  //ANCHOR - Use All Funds Button
                  if (input.asset.shouldShowUseAllFundsButton) ...{
                    SendAssetMaxButton(
                      isSelected: input.isSendAllFunds,
                      onPressed: () =>
                          notifier.setSendMaxAmount(!input.isSendAllFunds),
                    ),
                  },
                ],
              ),
            ),
          },

          const Spacer(),

          //ANCHOR - Continue Button
          Container(
            width: double.maxFinite,
            margin: const EdgeInsets.only(top: 12.0, bottom: 32.0),
            child: AquaElevatedButton(
              onPressed: isContinueButtonEnabled ? onContinuePressed : null,
              child: Text(context.loc.continueLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvertedAmountLabel extends ConsumerWidget {
  const _ConvertedAmountLabel(this.fiatAmount);

  final String fiatAmount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      "≈ $fiatAmount",
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class _LightningAmountConstraintsLabel extends ConsumerWidget {
  const _LightningAmountConstraintsLabel(this.constraints);

  final SendAssetAmountConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          '${context.loc.min}: ${constraints.minSats} sats',
          style: context.textTheme.titleSmall,
        ),
        const Spacer(),
        Text(
          '${context.loc.max}: ${constraints.maxSats} sats',
          style: context.textTheme.titleSmall,
        ),
      ],
    );
  }
}
