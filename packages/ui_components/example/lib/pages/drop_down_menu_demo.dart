import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

class DropDownMenuDemoPage extends HookConsumerWidget {
  const DropDownMenuDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final dropDownListKey = useMemoized(GlobalKey.new);
    final dropDownMenuKey = useMemoized(GlobalKey.new);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaTopAppBar(
              key: dropDownMenuKey,
              title: 'Drop Down (Menu)',
              colors: theme.colors,
              actions: [
                AquaIcon.more(
                  color: theme.colors.textPrimary,
                  onTap: () => AquaDropDown.showMenu(
                    context: context,
                    colors: theme.colors,
                    containerWidth: 240,
                    anchor: dropDownMenuKey.currentContext?.findRenderObject(),
                    items: ['Addresses', 'Swap Orders'],
                    onItemTap: (item) => debugPrint('Item $item tapped'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AquaTopAppBar(
              key: dropDownListKey,
              title: 'Drop Down (Custom)',
              colors: theme.colors,
              actions: [
                AquaIcon.more(
                  color: theme.colors.textPrimary,
                  onTap: () => AquaDropDown.show(
                    context: context,
                    colors: theme.colors,
                    containerWidth: 240,
                    anchor: dropDownListKey.currentContext?.findRenderObject(),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 3,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) => AquaListItem(
                        title: 'Item ${index + 1}',
                        subtitle: 'Subtitle ${index + 1}',
                        onTap: () {
                          debugPrint('Item ${index + 1} tapped');
                          AquaDropDown.dismiss();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
