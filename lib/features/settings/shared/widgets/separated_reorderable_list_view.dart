import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SeparatedReorderableListView extends ReorderableListView {
  SeparatedReorderableListView.separated({
    Key? key,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    required ReorderCallback onReorder,
    double? itemExtent,
    Widget? prototypeItem,
    ReorderItemProxyDecorator? proxyDecorator,
    bool buildDefaultDragHandles = true,
    EdgeInsets? padding,
    Widget? header,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController? scrollController,
    bool? primary,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    double anchor = 0.0,
    double? cacheExtent,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    String? restorationId,
    Clip clipBehavior = Clip.hardEdge,
  }) : super.builder(
          key: key,
          itemCount: max(0, itemCount * 2 - 1),
          itemBuilder: (BuildContext context, int index) {
            if (index % 2 == 1) {
              final separator = separatorBuilder.call(context, index);

              if (separator.key == null) {
                return KeyedSubtree(
                  key: ValueKey('ReorderableSeparator${index}Key'),
                  child: IgnorePointer(child: separator),
                );
              }

              return separator;
            }

            return itemBuilder.call(context, index ~/ 2);
          },
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }

            if (oldIndex % 2 == 1) {
              //separator - should never happen
              return;
            }

            if ((oldIndex - newIndex).abs() == 1) {
              //moved behind the top/bottom separator
              return;
            }

            newIndex = oldIndex > newIndex && newIndex % 2 == 1
                ? (newIndex + 1) ~/ 2
                : newIndex ~/ 2;
            oldIndex = oldIndex ~/ 2;
            onReorder.call(oldIndex, newIndex);
          },
          itemExtent: itemExtent,
          prototypeItem: prototypeItem,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: buildDefaultDragHandles,
          padding: padding,
          header: header,
          scrollDirection: scrollDirection,
          reverse: reverse,
          scrollController: scrollController,
          primary: primary,
          physics: physics,
          shrinkWrap: shrinkWrap,
          anchor: anchor,
          cacheExtent: cacheExtent,
          dragStartBehavior: dragStartBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
        );
}
