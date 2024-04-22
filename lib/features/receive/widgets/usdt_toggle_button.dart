import 'package:aqua/common/widgets/tab_switch_view.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

enum UsdtOption { liquid, trx, eth }

extension UsdtOptionExtension on UsdtOption {
  String networkLabel(BuildContext context) => switch (this) {
        UsdtOption.eth => context.loc.eth,
        UsdtOption.trx => context.loc.tron,
        _ => context.loc.liquid,
      };
}

class UsdtToggleButton extends HookConsumerWidget {
  const UsdtToggleButton({
    super.key,
    required this.onOptionSelected,
    required this.initialIndex,
  });

  final void Function(UsdtOption) onOptionSelected;
  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabSwitchView(
      labels: UsdtOption.values.map((e) => e.networkLabel(context)).toList(),
      onChange: (index) => onOptionSelected(UsdtOption.values[index]),
      initialIndex: initialIndex,
    );
  }
}
