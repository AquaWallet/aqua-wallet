import 'package:aqua/features/shared/shared.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({
    Key? key,
    this.height = 1,
    this.dashWidth = 5,
    this.color = Colors.black,
  }) : super(key: key);

  final double height;
  final double dashWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
