import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/config/colors.dart';

class SplashTaglineText extends HookWidget {
  const SplashTaglineText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final baseStyle = useMemoized(
      () => const TextStyle(
        fontFamily: UiFontFamily.inter,
        fontWeight: FontWeight.w700,
        fontSize: 50,
        height: 1.3,
        letterSpacing: -0.47,
        color: AquaPrimitiveColors.palatinateBlue750,
      ),
    );

    final newlineCount =
        useMemoized(() => '\n'.allMatches(text).length, [text]);
    final textAlign = useMemoized(
      () => newlineCount >= 3 ? TextAlign.left : TextAlign.center,
      [newlineCount],
    );

    final textSpans = useMemoized(() {
      final spans = <TextSpan>[];
      final pattern = RegExp(r'\*\*(.*?)\*\*|\S+|\s+');
      final matches = pattern.allMatches(text);

      for (final match in matches) {
        final matchedText = match.group(0)!;
        if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
          final boldText = matchedText.substring(2, matchedText.length - 2);
          spans.add(TextSpan(
            text: boldText,
            style: baseStyle.copyWith(color: Colors.white),
          ));
        } else {
          spans.add(TextSpan(
            text: matchedText,
            style: baseStyle,
          ));
        }
      }
      return spans;
    }, [text]);

    return Text.rich(
      TextSpan(children: textSpans),
      textAlign: textAlign,
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }
}
