import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class USDtSwapMinMaxPanel extends HookConsumerWidget {
  const USDtSwapMinMaxPanel({
    required this.currency,
    required this.swapPair,
    super.key,
  });

  final FiatCurrency currency;
  final SwapPair swapPair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapArgs = useMemoized(
      () => SwapArgs(pair: swapPair),
      [swapPair],
    );
    final rate = ref.watch(swapOrderProvider(swapArgs)).valueOrNull?.rate;

    useEffect(() {
      ref.read(swapOrderProvider(swapArgs).notifier).getRate();
      return null;
    }, [swapPair]);

    final formatAmount = useCallback((Decimal usdAmount) {
      return ref.read(formatProvider).formatFiatAmount(
            amount: usdAmount,
            specOverride: FiatCurrency.usd.format,
            withSymbol: false,
          );
    }, []);

    return rate != null
        ? AquaText.caption1Medium(
            text: context.loc.amountRange(
              formatAmount(rate.max),
              formatAmount(rate.min),
            ),
          )
        : const SizedBox.shrink();
  }
}
