import 'package:aqua/features/depix/providers/depix_deposit_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DepixAmountEntryPage extends HookConsumerWidget {
  const DepixAmountEntryPage({super.key, required this.spec});

  final AmountEntrySpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isContinueEnabled = useMemoized(
      () => (double amount, bool reversed) {
        if (amount <= 0) return false;
        final amt = Decimal.parse(amount.toString());
        final out = !reversed
            ? amountEntryFiatToAssetAmount(amt, spec)
            : amountEntryAssetToFiatAmount(amt, spec);
        return out > Decimal.zero;
      },
      [spec],
    );

    final onContinue = useMemoized(
      () => (double amount, bool isReversed) => ref
          .read(depixDepositProvider.notifier)
          .submitFromAmountEntry(amount, isReversed, spec),
      [spec],
    );

    return AmountEntryBody(
      props: AmountEntryScreenProps(
        spec: spec,
        buttonText: context.loc.next,
        isContinueEnabled: isContinueEnabled,
        onContinue: onContinue,
      ),
    );
  }
}
