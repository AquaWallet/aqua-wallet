import 'package:aqua/features/shared/shared.dart';

class MiddleEllipsisText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int startLength;
  final int endLength;
  final int ellipsisLength;

  const MiddleEllipsisText({
    super.key,
    required this.text,
    this.style,
    this.startLength = 10,
    this.endLength = 10,
    this.ellipsisLength = 3,
  });

  @override
  Widget build(BuildContext context) {
    final ellipsis = '.' * ellipsisLength;

    if (text.length <= startLength + endLength) {
      return Text(text, style: style);
    } else {
      final start = text.substring(0, startLength);
      final end = text.substring(text.length - endLength);
      return Text(
        '$start$ellipsis$end',
        style: style,
      );
    }
  }
}
