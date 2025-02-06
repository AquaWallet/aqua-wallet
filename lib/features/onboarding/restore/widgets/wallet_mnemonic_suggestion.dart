import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
      height: 43.0,
      color: Theme.of(context).colorScheme.primary,
      child: suggestions.isEmpty
          ? const SizedBox.shrink()
          //ANCHOR - Suggestions
          : ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => VerticalDivider(
                width: 16.0,
                indent: 8.0,
                endIndent: 8.0,
                thickness: 1.0,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: TextButton(
                    onPressed: () => onSuggestionSelected(text),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    child: Text(text.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}
