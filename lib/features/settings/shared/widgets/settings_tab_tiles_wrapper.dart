import 'package:aqua/features/settings/region/providers/region_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

class SettingsTabTilesWrapper extends HookConsumerWidget {
  const SettingsTabTilesWrapper({
    super.key,
    required this.items,
  });

  final List<Widget> Function(bool useSubtitle) items;

  void _checkOverflow(
    BuildContext context,
    ValueNotifier<bool> useSubtitle,
  ) {
    final maxWidth =
        (context.size?.width ?? MediaQuery.of(context).size.width) / 1.5;
    final testWidgets = items(false);
    const style = AquaTypography.body1SemiBold;

    for (final widget in testWidgets) {
      if (widget is AquaListItem) {
        final trailingText = widget.subtitleTrailing;
        if (trailingText != null) {
          final painter = TextPainter(
            text: TextSpan(text: trailingText + widget.title, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: maxWidth);

          if (painter.didExceedMaxLines) {
            if (!useSubtitle.value) useSubtitle.value = true;
            return;
          }
        }
      }
    }

    if (useSubtitle.value) useSubtitle.value = false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSubtitle = useState(false);
    final hasChecked = useRef(false);
    final regionsState = ref.watch(regionsProvider);

    useEffect(() {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkOverflow(context, useSubtitle));
      return null;
    }, [regionsState]);

    useEffect(() {
      if (hasChecked.value) return null;
      hasChecked.value = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkOverflow(context, useSubtitle));
      return null;
    }, const []);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items(useSubtitle.value),
      ),
    );
  }
}
