import 'package:aqua/config/config.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class WalletRestoreInputKeyboard extends HookConsumerWidget {
  const WalletRestoreInputKeyboard({
    super.key,
    required this.onKeyPressed,
  });

  final Function(MnemonicKeyboardKey key) onKeyPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCapsLock = ref.watch(mnemonicKeyboardCapsLockStatusProvider);

    return Container(
      height: double.maxFinite,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colors.keyboardBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _KeyboardRow(
            chars: ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']
                .toMnemonicKeyboardKeys(capitalized: isCapsLock),
            horizontalPadding: 12.0,
            onKeyPressed: onKeyPressed,
          ),
          _KeyboardRow(
            chars: ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']
                .toMnemonicKeyboardKeys(capitalized: isCapsLock),
            horizontalPadding: 32.0,
            onKeyPressed: onKeyPressed,
          ),
          _KeyboardRow(
            chars: ['z', 'x', 'c', 'v', 'b', 'n', 'm'].toMnemonicKeyboardKeys(
              capitalized: isCapsLock,
              withSpecialKeys: true,
            ),
            horizontalPadding: 12.0,
            onKeyPressed: onKeyPressed,
          ),
        ],
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({
    required this.horizontalPadding,
    required this.chars,
    required this.onKeyPressed,
  });

  final double horizontalPadding;
  final List<MnemonicKeyboardKey> chars;
  final Function(MnemonicKeyboardKey key) onKeyPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      alignment: Alignment.center,
      transformAlignment: Alignment.center,
      margin: !chars.containsSpecialKeys
          ? const EdgeInsets.only(bottom: 6.0)
          : null,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListView.separated(
        shrinkWrap: true,
        primary: false,
        itemCount: chars.length,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(width: 6.0),
        itemBuilder: (_, index) => _KeyboardKey(
          value: chars[index],
          onTap: onKeyPressed,
        ),
      ),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    required this.onTap,
    required this.value,
  });

  final MnemonicKeyboardKey value;
  final Function(MnemonicKeyboardKey key) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: value.isSpecialKey ? 56.0 : 35.0,
      height: 59.0,
      child: ElevatedButton(
        onPressed: () => onTap(value),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.all(2.0),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Theme.of(context).colors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: value.when(
          letter: (char) => Text(
            char,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 26.0,
                ),
          ),
          backspace: () => SvgPicture.asset(
            Svgs.backspace,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colors.onBackground,
              BlendMode.srcIn,
            ),
          ),
          capsLock: () => SvgPicture.asset(
            Svgs.capsLock,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colors.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
