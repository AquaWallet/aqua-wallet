import 'package:aqua/common/widgets/tab_switch_view.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/receive/providers/receive_asset_address_provider.dart';
import 'package:aqua/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

enum LayerTwoOption { lightning, lbtc }

class LayerTwoToggleButton extends HookConsumerWidget {
  const LayerTwoToggleButton({
    super.key,
    required this.onOptionSelected,
    required this.initialIndex,
  });

  final void Function(LayerTwoOption) onOptionSelected;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabSwitchView(
      labels: [context.loc.lightning, context.loc.liquid],
      onChange: (index) {
        ref.invalidate(receiveAssetAddressProvider);
        ref.invalidate(receiveAssetAmountProvider);
        ref.read(sideshiftOrderProvider).stopAllStreams();
        onOptionSelected(LayerTwoOption.values[index]);
      },
      initialIndex: initialIndex,
    );
  }
}
