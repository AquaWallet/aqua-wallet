import 'dart:math' as math;

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum SettingsListItemPosition { top, middle, bottom }

class SettingsItem {
  final String name;
  final Object object;
  final SettingsListItemPosition position;

  SettingsItem._(
    this.object, {
    required this.name,
    required this.position,
  });

  factory SettingsItem.create(
    Object object, {
    required String name,
    required int index,
    required int length,
  }) {
    final position = index == 0
        ? SettingsListItemPosition.top
        : index == length - 1
            ? SettingsListItemPosition.bottom
            : SettingsListItemPosition.middle;
    return SettingsItem._(object, name: name, position: position);
  }
}

class SettingsSelectionList extends HookWidget {
  const SettingsSelectionList({
    super.key,
    this.label,
    this.showSearch = false,
    this.includeAppBarPadding = true,
    required this.items,
    required this.itemBuilder,
    this.padding,
    this.filter,
  });

  final String? label;
  final bool showSearch;
  final List<SettingsItem> items;
  final SettingsListSelectionItem? Function(BuildContext, SettingsItem)
      itemBuilder;
  final EdgeInsets? padding;

  /// Returns null to exclude, or an int priority (lower = first).
  /// If not provided, uses default startsWith filter with priority 0.
  final int? Function(SettingsItem item, String query)? filter;
  final bool includeAppBarPadding;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final query = useState('');

    final listItems = useMemoized(() {
      if (query.value.isEmpty) return items;
      final filterFn = filter ??
          (SettingsItem item, String q) =>
              item.name.toLowerCase().startsWith(q.toLowerCase()) ? 0 : null;
      final scored = <(SettingsItem, int)>[];
      for (final item in items) {
        final priority = filterFn(item, query.value);
        if (priority != null) scored.add((item, priority));
      }
      scored.sort((a, b) {
        final cmp = a.$2.compareTo(b.$2);
        if (cmp != 0) return cmp;
        return a.$1.name.compareTo(b.$1.name);
      });
      return scored.map((e) => e.$1).toList();
    }, [query.value, items, filter]);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeAppBarPadding) ...{
            //ANCHOR - Padding to account for the app bar
            const AppBarPadding(),
          },
          //ANCHOR - Label
          if (label != null) SettingsListSelectionHeader(title: label ?? ''),
          //ANCHOR - Search bar
          if (showSearch) ...{
            AquaSearchField(
              controller: controller,
              hint: context.loc.searchTitle,
              onChanged: (value) => query.value = value,
            ),
            const SizedBox(height: 16),
          },
          //ANCHOR - Content
          Column(children: [
            //ANCHOR - List items
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(8), // Match container's border radius
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: listItems.length,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) =>
                    itemBuilder.call(context, listItems[index]),
                separatorBuilder: (context, index) => AquaDivider(
                  colors: context.aquaColors,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class SettingsListSelectionItem<T> extends StatelessWidget {
  const SettingsListSelectionItem({
    super.key,
    this.content,
    this.icon,
    this.collapsed = true,
    this.elevation = 0,
    this.onPressed,
    this.title,
    this.isRadioButton = false,
    this.radioValue,
    this.radioGroupValue,
    this.iconTrailing,
    this.subTitle,
  });

  final Widget? icon;
  final Widget? iconTrailing;
  final Widget? content;
  final String? title;
  final String? subTitle;
  final double elevation;
  final bool collapsed;
  final VoidCallback? onPressed;
  final bool isRadioButton;
  final T? radioValue;
  final T? radioGroupValue;

  @override
  Widget build(BuildContext context) {
    if (isRadioButton && iconTrailing != null) {
      throw Exception(
          'If isRadioButton is true, there shouldn"t be iconTrailing');
    }
    return AquaListItem(
      onTap: onPressed,
      iconLeading: icon,
      contentWidget: content,
      title: title ?? '',
      subtitle: subTitle ?? '',
      iconTrailing: isRadioButton
          ? AquaRadio<T?>.small(
              value: radioValue,
              groupValue: radioGroupValue,
              colors: context.aquaColors,
            )
          : iconTrailing,
    );
  }
}

class SettingsListSelectionHeader extends StatelessWidget {
  const SettingsListSelectionHeader({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            SizedBox.square(
              dimension: 15,
              child: Transform.rotate(
                angle: -90 * math.pi / 180,
                child: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
