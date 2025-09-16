import 'package:coin_cz/common/widgets/colored_text.dart';
import 'package:coin_cz/features/shared/shared.dart';

class MiddleEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int startLength;
  final int endLength;
  final int ellipsisLength;
  final ColoredTextEnum colorType;

  const MiddleEllipsisText({
    super.key,
    required this.text,
    this.style,
    this.startLength = 10,
    this.endLength = 10,
    this.ellipsisLength = 3,
    this.colorType = ColoredTextEnum.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    final ellipsis = '.' * ellipsisLength;

    if (text.length <= startLength + endLength) {
      return ColoredText(
        text: text,
        style: style,
        colorType: colorType,
      );
    } else {
      final start = text.substring(0, startLength);
      final end = text.substring(text.length - endLength);
      return ColoredText(
        text: '$start$ellipsis$end',
        style: style,
        colorType: colorType,
      );
    }
  }
}
