import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

class StylizedDivider extends StatelessWidget {
  const StylizedDivider({
    this.padding,
    this.color,
    super.key,
  });

  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Divider(
        height: 1.0,
        color: color ?? context.aquaColors.surfaceBorderSecondary,
      ),
    );
  }
}
