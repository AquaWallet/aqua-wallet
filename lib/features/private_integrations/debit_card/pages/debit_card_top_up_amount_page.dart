import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebitCardTopUpAmountPage extends HookConsumerWidget {
  const DebitCardTopUpAmountPage({
    super.key,
    required this.onInvoiceGenerated,
  });

  final VoidCallback onInvoiceGenerated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final input = ref.watch(topUpInputStateProvider).value;
    final error =
        ref.watch(topUpAmountValidationProvider).error as ExceptionLocalized?;
    final isValidAmount =
        ref.watch(topUpAmountValidationProvider).valueOrNull ?? false;
    final currency = ref.watch(exchangeRatesProvider.select(
      (p) => p.currentCurrency.currency.value,
    ));
    final isContinueButtonEnabled = useMemoized(
      () => error == null && isValidAmount,
      [error, isValidAmount],
    );

    ref
      ..listen(topUpInputStateProvider, (_, state) {
        controller.text = state.value!.amountFieldText ?? '';
      })
      ..listen(topUpInvoiceProvider, (_, state) {
        if (state.valueOrNull?.invoice != null) {
          onInvoiceGenerated();
        }
      });

    if (input == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          //ANCHOR - Asset Selector
          Text(
            context.loc.useBalanceFrom,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.onBackground,
              fontFamily: UiFontFamily.inter,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          //ANCHOR - Asset Selector
          const DebitCardAddBalanceAssetPicker(),
          const SizedBox(height: 13),
          //ANCHOR - Asset Selector
          Text(
            context.loc.setAmount,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.onBackground,
              fontFamily: UiFontFamily.inter,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          //ANCHOR - Amount Input
          SendAssetAmountInput(
            controller: controller,
            symbol: input.isFiatAmountInput ? currency : input.asset.ticker,
            allowUsdToggle: input.asset.shouldAllowUsdToggleOnSend,
            precision: input.asset.precision,
            backgroundColor: context.colors.dropdownMenuBackground,
            onChanged: (text) =>
                ref.read(topUpInputStateProvider.notifier).setAmount(text),
            onCurrencyTypeToggle: () =>
                ref.read(topUpInputStateProvider.notifier).setInputType(
                      input.isFiatAmountInput
                          ? CryptoAmountInputType.crypto
                          : CryptoAmountInputType.fiat,
                    ),
          ),
          const SizedBox(height: 8),
          //ANCHOR - Min/Max Limits
          //TODO - Add min/max limits from Moon API
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.loc.minValue(10),
                style: TextStyle(
                  color:
                      context.colors.debitCardAddBalanceMinMaxAmountLabelColor,
                  fontSize: 12,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.loc.maxValue('2,000'),
                style: TextStyle(
                  color:
                      context.colors.debitCardAddBalanceMinMaxAmountLabelColor,
                  fontSize: 12,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (error != null) ...{
            //ANCHOR - Error Message
            Text(
              error.toLocalizedString(context),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            )
          },
          const Spacer(),
          //ANCHOR - Continue Button
          AquaElevatedButton(
            height: 52,
            style: ElevatedButton.styleFrom(
              backgroundColor: AquaColors.vividSkyBlue,
              textStyle: TextStyle(
                fontSize: 20,
                height: 1.05,
                color: context.colorScheme.onPrimary,
                fontFamily: UiFontFamily.helveticaNeue,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: isContinueButtonEnabled
                ? ref.read(topUpInvoiceProvider.notifier).generateInvoice
                : null,
            child: ref.watch(topUpInvoiceProvider).isLoading
                ? const CircularProgressIndicator()
                : Text(context.loc.continueLabel),
          ),
          const SizedBox(height: 42),
        ],
      ),
    );
  }
}
