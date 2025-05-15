import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _keys = [
  ...List.generate(
    9,
    (index) => MnemonicKeyboardKey.letter(text: '${index + 1}'),
  ),
  MnemonicKeyboardKey.letter(text: '.'),
  MnemonicKeyboardKey.letter(text: '0'),
  MnemonicKeyboardKey.backspace(),
];

class AquaNumpad extends HookWidget {
  const AquaNumpad({
    super.key,
    this.enabled = true,
    this.onKeyPressed,
    required this.colors,
  });

  final bool enabled;
  final void Function(MnemonicKeyboardKey)? onKeyPressed;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.zero,
      childAspectRatio: 1.95,
      children: _keys
          .map((key) => _AquaNumpadKey(
                key: ValueKey(key),
                value: key,
                enabled: enabled,
                onPressed: onKeyPressed,
                colors: colors,
              ))
          .toList(),
    );
  }
}

class _AquaNumpadKey extends StatelessWidget {
  const _AquaNumpadKey({
    super.key,
    required this.value,
    required this.enabled,
    this.onPressed,
    required this.colors,
  });

  final MnemonicKeyboardKey value;
  final bool enabled;
  final void Function(MnemonicKeyboardKey)? onPressed;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onPressed?.call(value) : null,
        child: Container(
          alignment: Alignment.center,
          child: AquaText.h4Medium(
            text: switch (value) {
              MnemonicKeyboardLetterKey(:final text) => text,
              MnemonicKeyboardBackspaceKey() => '⌫',
            },
            color: enabled
                ? colors.textPrimary
                : colors.textPrimary.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
