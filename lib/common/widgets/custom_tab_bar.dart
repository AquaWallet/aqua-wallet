import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    super.key,
    required this.tabTitles,
    required this.selectedIndex,
    required this.onSelected,
    this.tabSubtitles = const [],
    this.mainAxisAlignment,
    this.selectedColor,
    this.backgroundColor,
    this.secondarySelectedColor,
    this.disabledColor,
    this.labelStyle,
    this.secondaryLabelStyle,
    this.shape,
    this.width,
    this.padding = EdgeInsets.zero,
  });

  final List<String> tabTitles;
  final List<String> tabSubtitles;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final MainAxisAlignment? mainAxisAlignment;

  final Color? selectedColor;
  final Color? backgroundColor;
  final Color? secondarySelectedColor;
  final Color? disabledColor;
  final TextStyle? labelStyle;
  final TextStyle? secondaryLabelStyle;
  final OutlinedBorder? shape;
  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        chipTheme: ChipThemeData(
          brightness: Brightness.dark,
          selectedColor: selectedColor ?? Theme.of(context).colorScheme.surface,
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
          secondarySelectedColor:
              secondarySelectedColor ?? Theme.of(context).colorScheme.surface,
          disabledColor:
              disabledColor ?? Theme.of(context).colorScheme.primaryContainer,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.h),
          labelStyle: labelStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onBackground,
                  ) ??
              const TextStyle(),
          secondaryLabelStyle: secondaryLabelStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ) ??
              const TextStyle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
      ),
      child: Container(
        height: 68.h,
        padding: padding,
        child: Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          children: tabTitles.mapIndexed((index, tab) {
            final left = index == 0
                ? 0.w
                : padding == EdgeInsets.zero
                    ? 12.w
                    : .0;
            return Padding(
              padding: EdgeInsets.only(left: left),
              child: SizedBox(
                width: width,
                child: ChoiceChip(
                  labelPadding: EdgeInsets.zero,
                  label: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (tabSubtitles.length > index)
                          Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            child: Text(
                              tabSubtitles[index],
                              style: index == selectedIndex
                                  ? secondaryLabelStyle
                                  : secondaryLabelStyle?.copyWith(
                                      color: selectedColor,
                                    ),
                            ),
                          ),
                        Text(
                          tabTitles[index],
                          style: labelStyle,
                        ),
                      ],
                    ),
                  ),
                  shape: shape,
                  selected: index == selectedIndex,
                  onSelected: (bool newValue) {
                    if (newValue) onSelected(index);
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
