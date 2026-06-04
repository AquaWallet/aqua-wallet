import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LnAddressTotalFeesRow extends ConsumerWidget {
  const LnAddressTotalFeesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(lnUsernameUpdateProductProvider);
    final product = productAsync.valueOrNull;

    if (product == null) {
      return AquaListItem(
        title: context.loc.totalFees,
        titleTrailing: '-',
        subtitleTrailing: '-',
      );
    }

    final formatter = ref.read(formatProvider);
    final displayUnits = ref.read(displayUnitsProvider);
    final formatted =
        formatLnUsernameUpdateFee(formatter, displayUnits, product);
    return AquaListItem(
      title: context.loc.totalFees,
      titleTrailing: formatted.usdtTrailing,
      subtitleTrailing: formatted.satsUnitTrailing,
    );
  }
}
