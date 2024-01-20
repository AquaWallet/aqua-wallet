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
    return Ink(
      height: 40.h,
      color: Theme.of(context).colorScheme.onBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => controller.animateTo(
              controller.offset - 100.w,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            ),
            splashRadius: 20.r,
            splashColor: Colors.transparent,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.background,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  child: ElevatedButton(
                    onPressed: () => onSuggestionSelected(text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    child: Text(text),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => controller.animateTo(
              controller.offset + 100.w,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            ),
            splashRadius: 20.r,
            splashColor: Colors.transparent,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.background,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
