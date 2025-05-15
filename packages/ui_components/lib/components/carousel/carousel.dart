import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaCarousel extends HookWidget {
  const AquaCarousel({
    super.key,
    required this.children,
    required this.colors,
    this.maxContentHeight,
  });

  final List<Widget> children;
  final AquaColors? colors;
  final double? maxContentHeight;

  static const margin = 8.0;

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(viewportFraction: 0.9);
    final tabController = useTabController(
      initialLength: children.length,
    );

    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: maxContentHeight ?? 220,
          ),
          child: PageView.builder(
            controller: pageController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: children.length,
            padEnds: true,
            onPageChanged: (index) => tabController.animateTo(index),
            itemBuilder: (_, index) => Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsetsDirectional.only(end: margin),
              child: children[index],
            ),
          ),
        ),
        const SizedBox(height: 24),
        //ANCHOR - Index Indicators
        _CardSelectionIndicator(
          controller: tabController,
          fixColor: colors?.textTertiary ??
              Theme.of(context).colorScheme.onSurfaceVariant,
          fixSelectedColor:
              colors?.textPrimary ?? Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }
}

// Customized copy of [TabPageSelectorIndicator] to fit our design
class _CardSelectionIndicator extends HookWidget {
  const _CardSelectionIndicator({
    required this.controller,
    required this.fixColor,
    required this.fixSelectedColor,
  });

  final TabController controller;
  final Color fixColor;
  final Color fixSelectedColor;

  @override
  Widget build(BuildContext context) {
    final selectedColorTween =
        ColorTween(begin: fixColor, end: fixSelectedColor);
    final previousColorTween =
        ColorTween(begin: fixSelectedColor, end: fixColor);
    final animation = useListenable(CurvedAnimation(
      parent: controller.animation!,
      curve: Curves.fastOutSlowIn,
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Semantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              controller.length,
              (index) => _buildTabIndicator(
                    index,
                    controller,
                    selectedColorTween,
                    previousColorTween,
                  )).toList(),
        ),
      ),
    );
  }

  double _indexChangeProgress(TabController controller) {
    final controllerValue = controller.animation!.value;
    final prevIndex = controller.previousIndex.toDouble();
    final currIndex = controller.index.toDouble();

    if (!controller.indexIsChanging) {
      return clampDouble((currIndex - controllerValue).abs(), 0.0, 1.0);
    }

    return (controllerValue - currIndex).abs() / (currIndex - prevIndex).abs();
  }

  Widget _buildTabIndicator(
    int tabIndex,
    TabController tabController,
    ColorTween selectedColorTween,
    ColorTween previousColorTween,
  ) {
    final Color background;
    final isSelectedIndex = tabController.index == tabIndex;
    if (tabController.indexIsChanging) {
      // The selection's animation is animating from previousValue to value.
      final double t = 1.0 - _indexChangeProgress(tabController);
      if (tabController.index == tabIndex) {
        background = selectedColorTween.lerp(t)!;
      } else if (tabController.previousIndex == tabIndex) {
        background = previousColorTween.lerp(t)!;
      } else {
        background = selectedColorTween.begin!;
      }
    } else {
      // The selection's offset reflects how far the TabBarView has / been dragged
      // to the previous page (-1.0 to 0.0) or the next page (0.0 to 1.0).
      final double offset = tabController.offset;
      if (isSelectedIndex) {
        background = selectedColorTween.lerp(1.0 - offset.abs())!;
      } else if (tabController.index == tabIndex - 1 && offset > 0.0) {
        background = selectedColorTween.lerp(offset)!;
      } else if (tabController.index == tabIndex + 1 && offset < 0.0) {
        background = selectedColorTween.lerp(-offset)!;
      } else {
        background = selectedColorTween.begin!;
      }
    }
    return Container(
      width: isSelectedIndex ? 24 : 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
