import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class CountryFlag extends StatelessWidget {
  const CountryFlag({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    required this.svgAsset,
  });

  final String svgAsset;
  final double? width;
  final double? height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 2.0),
      child: SvgPicture.asset(
        svgAsset,
        width: width ?? 16.0,
        height: height ?? 16.0,
      ),
    );
  }
}
