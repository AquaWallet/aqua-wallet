import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';

class SwapConversionRateView extends HookConsumerWidget {
  const SwapConversionRateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(swapLoadingIndicatorStateProvider).isConnecting;
    final inputState = ref.watch(sideswapInputStateProvider);
    final amount = ref.watch(sideswapConversionRateAmountProvider);
    final error = ref.watch(swapValidationsProvider(context));

    return switch (null) {
      _ when isLoading => Container(
          height: 42.0,
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          child: const Align(
            alignment: Alignment.center,
            child: Text('1 BTC = 1 L-BTC'),
          ),
        ),
      _ when inputState.isPeg => _RateTextContainer(
          text: context.loc.conversionRate99,
        ),
      _ when amount == null || error != null => Container(
          height: 42.0,
          margin: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      _ => _RateTextContainer(text: amount),
    };
  }
}

class _RateTextContainer extends StatelessWidget {
  const _RateTextContainer({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.0,
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: BoxShadowContainer(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.conversionRateSwapScreenColor,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: [
            Theme.of(context).swapScreenRateConversionBoxShadows,
          ],
        ),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // TODO: convert to AssetCryptoAmount
            child: Text(
              text,
              style: context.textTheme.labelLarge?.copyWith(
                fontSize: 13.0,
                color: context.colors.swapConversionRateViewTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
