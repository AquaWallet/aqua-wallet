import 'package:aqua/features/shared/shared.dart';

class StylizedVerticalDivider extends StatelessWidget {
  const StylizedVerticalDivider({
    this.padding,
    required this.color,
    super.key,
  });

  final Color color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
      child: VerticalDivider(
        indent: 4,
        endIndent: 4,
        width: 1.0,
        color: color,
      ),
    );
  }
}
