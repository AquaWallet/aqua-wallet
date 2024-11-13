import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final kBoldPattern = RegExp(r'\*\*(.*?)\*\*');

typedef Word = (bool isBold, String text);

class OnboardingTagline extends HookWidget {
  const OnboardingTagline({
    super.key,
    this.onTap,
    this.onLongPress,
    required this.description,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textStyle = useMemoized(() => TextStyle(
          height: 1.1,
          wordSpacing: 0,
          letterSpacing: -2.2,
          fontSize: 52.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: UiFontFamily.dMSans,
        ));

    final wordsWithSpaces = useMemoized(() {
      final words = description.split(' ');
      return words.mapIndexed((index, word) {
        final isLast = index == words.length - 1;
        final boldWord = kBoldPattern.firstMatch(word);
        final text = boldWord != null ? boldWord.group(1)! : word;
        return (
          isBold: boldWord != null,
          text: isLast ? text : '$text ',
        );
      }).toList();
    }, [description]);

    return GestureDetector(
      onTap: kDebugMode ? onTap : null,
      onLongPress: kDebugMode ? onLongPress : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        margin: EdgeInsetsDirectional.only(
          bottom: 10.h,
          end: 6.w, // FIXME: TEMP fix for design asymmetry
        ),
        child: Material(
          color: Colors.transparent,
          child: Text.rich(
            style: textStyle,
            textAlign: TextAlign.center,
            TextSpan(
              children: wordsWithSpaces
                  .map((word) => TextSpan(
                        text: word.text,
                        style: word.isBold
                            ? textStyle.copyWith(color: AquaColors.vividSkyBlue)
                            : textStyle,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
