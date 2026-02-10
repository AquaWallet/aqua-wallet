import 'dart:math';

import 'package:flutter/material.dart';

class SeparatedReorderableListView extends ReorderableListView {
  /// Helper method to build a drag handle for use with [handleOnlyMode].
  ///
  /// When [handleOnlyMode] is true, wrap your drag handle widget (e.g., a grab icon)
  /// with this method to enable drag-and-drop only when that widget is touched.
  ///
  /// The [index] should be the item index (0-based, not including separators).
  /// The [child] is the widget that will act as the drag handle.
  static Widget buildDragHandle({
    required int index,
    required Widget child,
  }) {
    return ReorderableDragStartListener(
      // Multiply by 2 to account for separator items in the internal list
      index: index * 2,
      child: child,
    );
  }

  SeparatedReorderableListView.separated({
    super.key,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    required ReorderCallback onReorder,
    bool handleOnlyMode = false,
    super.itemExtent,
    super.prototypeItem,
    super.proxyDecorator,
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
          buildDefaultDragHandles: false,
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

            final itemIndex = index ~/ 2;
            final item = itemBuilder.call(context, itemIndex);

            // In handleOnlyMode, the caller is responsible for wrapping their
            // drag handle with buildDragHandle(). Otherwise, wrap the entire item.
            if (handleOnlyMode) {
              return KeyedSubtree(
                key: item.key ?? ValueKey('item_$itemIndex'),
                child: item,
              );
            }

            return ReorderableDragStartListener(
              key: ValueKey('item_$itemIndex'),
              index: index,
              child: item,
            );
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
