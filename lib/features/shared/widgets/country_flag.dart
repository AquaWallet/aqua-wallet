import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class CountryFlag extends StatelessWidget {
  const CountryFlag({
    super.key,
    required this.svgAsset,
    required this.size,
    this.borderRadius,
  });

  final String svgAsset;
  final double size;
  final double? borderRadius;

  static const _borderWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 2.0;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: context.aquaColors.surfaceBorderSecondary,
          width: _borderWidth,
        ),
      ),
      child: SvgPicture.asset(
        svgAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
