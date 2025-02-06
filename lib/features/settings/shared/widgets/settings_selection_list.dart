import 'dart:math' as math;

import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    required this.items,
    required this.itemBuilder,
  });

  final String? label;
  final bool showSearch;
  final List<SettingsItem> items;
  final SettingsListSelectionItem? Function(BuildContext, SettingsItem)
      itemBuilder;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final query = useState('');
    final listItems = useMemoized(
      () => items
          .where((item) =>
              item.name.toLowerCase().startsWith(query.value.toLowerCase()))
          .toList(),
      [query.value, items],
    );
    final clearSearchInput = useCallback(() {
      controller.clear();
      query.value = '';
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ANCHOR - Label
          if (label != null) SettingsListSelectionHeader(title: label ?? ''),
          const SizedBox(height: 22),
          //ANCHOR - Content
          BoxShadowContainer(
            padding: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: Column(children: [
              //ANCHOR - Search bar
              if (showSearch) ...{
                TextField(
                  controller: controller,
                  onChanged: (value) => query.value = value,
                  decoration: InputDecoration(
                    hintText: context.loc.regionSettingsScreenSearchHint,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colors.onBackground,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 18, right: 12),
                      child: SvgPicture.asset(
                        Svgs.search,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colors.onBackground,
                            BlendMode.srcIn),
                      ),
                    ),
                    suffixIcon: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 20, 15),
                        child: controller.text.isNotEmpty
                            ? ClearInputButton(onTap: clearSearchInput)
                            : null),
                    border: InputBorder.none,
                  ),
                ),
              },
              //ANCHOR - List items
              ClipRRect(
                borderRadius: BorderRadius.circular(
                    12), // Match container's border radius
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: listItems.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) =>
                      itemBuilder.call(context, listItems[index]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class SettingsListSelectionItem extends StatelessWidget {
  const SettingsListSelectionItem({
    super.key,
    required this.content,
    this.icon,
    this.position,
    this.collapsed = true,
    this.elevation = 0,
    this.onPressed,
  });

  final Widget? icon;
  final Widget content;
  final double elevation;
  final bool collapsed;
  final SettingsListItemPosition? position;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(12);
    final tapRadius = switch (position) {
      SettingsListItemPosition.top =>
        const BorderRadius.only(topLeft: radius, topRight: radius),
      SettingsListItemPosition.middle => BorderRadius.zero,
      SettingsListItemPosition.bottom =>
        const BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      _ => BorderRadius.circular(12),
    };

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: tapRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: tapRadius,
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 16),
              ],
              Expanded(child: content),
              SizedBox.square(
                dimension: 15,
                child: Transform.rotate(
                  angle: !collapsed ? -90 * math.pi / 180 : 0,
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
      ),
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
