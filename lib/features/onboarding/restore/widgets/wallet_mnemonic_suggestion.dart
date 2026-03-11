import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart' hide ResponsiveEx;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletMnemonicSuggestions extends HookConsumerWidget {
  const WalletMnemonicSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  final List<String> suggestions;
  final Function(String suggestion) onSuggestionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useScrollController();
    return Container(
      height: context.adaptiveDouble(mobile: 50.0, smallMobile: 45.0),
      color: context.aquaColors.surfacePrimary,
      child: suggestions.isEmpty
          ? const SizedBox.shrink()
          //ANCHOR - Suggestions
          : ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                //ANCHOR - Theme to change the button text color to the text primary color
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          onSurface: context.aquaColors.textPrimary,
                        ),
                  ),
                  child: AquaButton.tertiary(
                    onPressed: () => onSuggestionSelected(text),
                    text: text.toLowerCase(),
                    size: AquaButtonSize.small,
                  ),
                );
              },
            ),
    );
  }
}
