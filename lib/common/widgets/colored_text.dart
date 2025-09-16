import 'package:coin_cz/config/colors/colors.dart';
import 'package:coin_cz/features/shared/shared.dart';

class ColoredText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final ColoredTextEnum colorType;

  const ColoredText({
    super.key,
    required this.text,
    this.style,
    this.colorType = ColoredTextEnum.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (colorType) {
      case ColoredTextEnum.defaultColor:
        return Text(text, style: style);
      case ColoredTextEnum.coloredIntegers:
        return _getColoredIntegers(text, style, context);
    }
  }

  Widget _getColoredIntegers(
      String text, TextStyle? style, BuildContext context) {
    final RegExp numberPattern = RegExp(r'\d+');
    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (Match m in numberPattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(
            TextSpan(text: text.substring(lastEnd, m.start), style: style));
      }
      spans.add(TextSpan(
          text: m.group(0),
          style: (style ?? const TextStyle())
              .copyWith(color: AquaColors.backgroundSkyBlue)));
      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return RichText(text: TextSpan(children: spans, style: style));
  }
}

enum ColoredTextEnum {
  defaultColor,
  coloredIntegers,
}
