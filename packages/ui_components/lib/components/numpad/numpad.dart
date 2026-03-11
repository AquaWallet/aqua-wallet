import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaNumpad extends HookWidget {
  const AquaNumpad({
    super.key,
    this.enabled = true,
    this.decimalAllowed = true,
    this.onKeyPressed,
    required this.colors,
    this.decimalSeparator = MnemonicKeyboardKey.kDecimalCharacter,
  });

  final bool enabled;
  final bool decimalAllowed;
  final void Function(MnemonicKeyboardKey)? onKeyPressed;
  final AquaColors colors;
  final String decimalSeparator;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ...List.generate(9, (i) => MnemonicKeyboardKey.letter(text: '${i + 1}')),
      MnemonicKeyboardKey.letter(text: decimalSeparator),
      MnemonicKeyboardKey.letter(text: '0'),
      MnemonicKeyboardKey.backspace(),
    ];

    final isDecimalKey = useCallback((MnemonicKeyboardKey key) {
      return key is MnemonicKeyboardLetterKey && key.text == decimalSeparator;
    }, [decimalSeparator]);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.zero,
      childAspectRatio: 1.95,
      children: keys
          .map((key) => _AquaNumpadKey(
                key: ValueKey(key),
                value: key,
                enabled: enabled && (!isDecimalKey(key) || decimalAllowed),
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
        onTap: enabled && onPressed != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onPressed?.call(value))
            : null,
        splashFactory: InkRipple.splashFactory,
        child: Container(
          alignment: Alignment.center,
          child: AquaText.h4Medium(
            text: switch (value) {
              MnemonicKeyboardLetterKey(:final text) => text,
              MnemonicKeyboardBackspaceKey() =>
                MnemonicKeyboardKey.kBackspaceCharacter,
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
