import 'package:coin_cz/common/widgets/tab_switch_view.dart';
import 'package:coin_cz/features/receive/providers/receive_asset_amount_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

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
        ref.invalidate(receiveAssetAmountProvider);
        onOptionSelected(LayerTwoOption.values[index]);
      },
      initialIndex: initialIndex,
    );
  }
}
