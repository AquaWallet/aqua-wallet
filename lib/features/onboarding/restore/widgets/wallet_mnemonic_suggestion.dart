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
      height: 43.h,
      color: Theme.of(context).colorScheme.primary,
      child: suggestions.isEmpty
          ? const SizedBox.shrink()
          //ANCHOR - Suggestions
          : ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => VerticalDivider(
                width: 16.w,
                indent: 8.h,
                endIndent: 8.h,
                thickness: 1.w,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  child: TextButton(
                    onPressed: () => onSuggestionSelected(text),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
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
