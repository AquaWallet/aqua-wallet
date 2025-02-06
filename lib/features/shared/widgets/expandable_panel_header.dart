import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class ExpandablePanelHeader extends StatelessWidget {
  const ExpandablePanelHeader({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.state,
  });

  final String title;
  final ValueNotifier<bool> isExpanded;
  final AsyncValue state;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (!state.hasError) {
            isExpanded.value = !isExpanded.value;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                  ),
                ),
              ),
              Stack(
                children: [
                  state.when(
                    data: (_) => ExpandIcon(
                      onPressed: null,
                      disabledColor: context.colors.onBackground,
                      expandedColor: context.colors.onBackground,
                      isExpanded: isExpanded.value,
                    ),
                    loading: () => Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(8),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(8),
                      child: const Icon(Icons.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
