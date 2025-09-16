import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:decimal/decimal.dart';

class USDtSwapMinMaxPanel extends HookConsumerWidget {
  final SwapPair swapPair;

  const USDtSwapMinMaxPanel({
    required this.swapPair,
    super.key,
  });

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

    final formatAmount = useCallback((Decimal? amount) {
      final ticker = swapPair.to.ticker;
      return amount != null ? '${amount.toStringAsFixed(2)} $ticker' : '--';
    }, [swapPair]);

    final minAmount = rate?.min;
    final maxAmount = rate?.max;

    return Row(
      children: [
        Text(
          '${context.loc.min}: ${formatAmount(minAmount)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        Text(
          '${context.loc.max}: ${formatAmount(maxAmount)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
