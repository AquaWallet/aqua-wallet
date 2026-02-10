import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

/// A Flutter Hook that manages a [ColorCodedTextEditingController].
///
/// This hook provides a [ColorCodedTextEditingController] instance that is
/// automatically disposed when the widget is unmounted. Use this when you
/// want to display a [TextField] with custom text coloring logic (e.g.,
/// coloring numbers or patterns differently).
///
/// [text] sets the initial value of the controller.
/// [keys] can be used to control when the controller should be recreated.
///
/// Example:
/// ```dart
/// final controller = useColoredTextEditingController(text: '123 abc');
/// ```
ColorCodedTextEditingController useColorCodedTextEditingController({
  String? text,
  List<Object?>? keys,
}) {
  return use(
    _Hook(
      initialText: text,
      keys: keys,
    ),
  );
}

class _Hook extends Hook<ColorCodedTextEditingController> {
  const _Hook({
    this.initialText,
    super.keys,
  });

  final String? initialText;

  @override
  _HookState createState() => _HookState();
}

class _HookState extends HookState<ColorCodedTextEditingController, _Hook> {
  late final _controller =
      ColorCodedTextEditingController(text: hook.initialText);

  @override
  ColorCodedTextEditingController build(BuildContext context) => _controller;

  @override
  void dispose() => _controller.dispose();

  @override
  String get debugLabel => 'useColorCodedTextEditingController';
}
