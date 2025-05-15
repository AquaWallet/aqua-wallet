import 'package:flutter/widgets.dart';

extension WidgetStatesX on Set<WidgetState> {
  bool get isHovered =>
      contains(WidgetState.hovered) && !contains(WidgetState.pressed);

  bool get isDisabled => contains(WidgetState.disabled);

  bool get isSelected => contains(WidgetState.selected);

  bool get isFocused => contains(WidgetState.focused);

  bool get isPressed => contains(WidgetState.pressed);
}
