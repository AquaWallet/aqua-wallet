import 'dart:math';
import 'package:flutter/material.dart';

class SeparatedReorderableListView extends ReorderableListView {
  SeparatedReorderableListView.separated({
    super.key,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    required ReorderCallback onReorder,
    super.itemExtent,
    super.prototypeItem,
    super.proxyDecorator,
    super.buildDefaultDragHandles,
    super.padding,
    super.header,
    super.scrollDirection,
    super.reverse,
    super.scrollController,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.anchor,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : super.builder(
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
        );
}
