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
    final query = useState('');
    final listItems = useMemoized(
      () => items
          .where((item) =>
              item.name.toLowerCase().contains(query.value.toLowerCase()))
          .toList(),
      [query.value, items],
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ANCHOR - Label
          if (label != null) SettingsListSelectionHeader(title: label ?? ''),
          SizedBox(height: 22.h),
          //ANCHOR - Content
          BoxShadowContainer(
            padding: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            child: Column(children: [
              //ANCHOR - Search bar
              if (showSearch) ...{
                TextField(
                  onChanged: (value) => query.value = value,
                  decoration: InputDecoration(
                    hintText: context.loc.regionSettingsScreenSearchHint,
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    prefixIcon: Container(
                      margin: EdgeInsets.only(left: 18.w, right: 12.w),
                      child: SvgPicture.asset(
                        Svgs.search,
                        width: 16.r,
                        height: 16.r,
                        colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onBackground,
                            BlendMode.srcIn),
                      ),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              },
              //ANCHOR - List items
              ListView.builder(
                shrinkWrap: true,
                itemCount: listItems.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) =>
                    itemBuilder.call(context, listItems[index]),
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
    final radius = Radius.circular(12.r);
    final tapRadius = switch (position) {
      SettingsListItemPosition.top =>
        BorderRadius.only(topLeft: radius, topRight: radius),
      SettingsListItemPosition.middle => BorderRadius.zero,
      SettingsListItemPosition.bottom =>
        BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      _ => BorderRadius.circular(12.r),
    };

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: tapRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: tapRadius,
        child: Ink(
          height: 52.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 16.w),
              ],
              Expanded(child: content),
              SizedBox.square(
                dimension: 15.r,
                child: Transform.rotate(
                  angle: !collapsed ? -90 * math.pi / 180 : 0,
                  child: Icon(
                    Icons.arrow_forward_ios_sharp,
                    size: 15.r,
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Expanded(child: Text(title)),
            SizedBox.square(
              dimension: 15.r,
              child: Transform.rotate(
                angle: -90 * math.pi / 180,
                child: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: 15.r,
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
