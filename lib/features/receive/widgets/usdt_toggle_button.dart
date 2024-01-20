import 'package:aqua/common/widgets/tab_switch_view.dart';
import 'package:aqua/features/shared/shared.dart';

enum UsdtOption { liquid, eth, trx }

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
      labels: [
        AppLocalizations.of(context)!.liquid,
        AppLocalizations.of(context)!.eth,
        AppLocalizations.of(context)!.tron
      ],
      onChange: (index) => onOptionSelected(UsdtOption.values[index]),
      initialIndex: initialIndex,
    );
  }
}
