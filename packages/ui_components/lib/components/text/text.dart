import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

export 'colored_text.dart';

class AquaText extends StatelessWidget {
  const AquaText.h1({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h1;
  const AquaText.h2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h2;
  const AquaText.h3({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h3;
  const AquaText.h4({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h4;
  const AquaText.h5({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h5;
  const AquaText.subtitle({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.subtitle;
  const AquaText.body1({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body1;
  const AquaText.body2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body2;
  const AquaText.caption1({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption1;
  const AquaText.caption2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption2;

  const AquaText.h1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h1Medium;
  const AquaText.h2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h2Medium;
  const AquaText.h3Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h3Medium;
  const AquaText.h4Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h4Medium;
  const AquaText.h5Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h5Medium;
  const AquaText.subtitleMedium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.subtitleMedium;
  const AquaText.body1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body1Medium;
  const AquaText.body2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body2Medium;
  const AquaText.caption1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption1Medium;
  const AquaText.caption2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption2Medium;

  const AquaText.h1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h1SemiBold;
  const AquaText.h2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h2SemiBold;
  const AquaText.h3SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h3SemiBold;
  const AquaText.h4SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h4SemiBold;
  const AquaText.h5SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.h5SemiBold;
  const AquaText.subtitleSemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.subtitleSemiBold;
  const AquaText.body1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body1SemiBold;
  const AquaText.body2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.body2SemiBold;
  const AquaText.caption1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption1SemiBold;
  const AquaText.caption2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
  }) : style = AquaTypography.caption2SemiBold;

  final String text;
  final TextStyle style;
  final Color? color;
  final double? size;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      style: style.copyWith(
        color: color,
        fontSize: size,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
