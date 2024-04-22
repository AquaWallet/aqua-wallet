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
            horizontalPadding: 12.w,
            onKeyPressed: onKeyPressed,
          ),
          _KeyboardRow(
            chars: ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']
                .toMnemonicKeyboardKeys(capitalized: isCapsLock),
            horizontalPadding: 32.w,
            onKeyPressed: onKeyPressed,
          ),
          _KeyboardRow(
            chars: ['z', 'x', 'c', 'v', 'b', 'n', 'm'].toMnemonicKeyboardKeys(
              capitalized: isCapsLock,
              withSpecialKeys: true,
            ),
            horizontalPadding: 12.w,
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
      height: 60.h,
      alignment: Alignment.center,
      transformAlignment: Alignment.center,
      margin: !chars.containsSpecialKeys ? EdgeInsets.only(bottom: 6.h) : null,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ListView.separated(
        shrinkWrap: true,
        primary: false,
        itemCount: chars.length,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: 6.w),
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
      width: value.isSpecialKey ? 56.w : 35.w,
      height: 59.h,
      child: ElevatedButton(
        onPressed: () => onTap(value),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.all(2.r),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: Theme.of(context).colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        child: value.when(
          letter: (char) => Text(
            char,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 26.sp,
                ),
          ),
          backspace: () => SvgPicture.asset(
            Svgs.backspace,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
          capsLock: () => SvgPicture.asset(
            Svgs.capsLock,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
