import 'dart:ui';

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
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h1;

  const AquaText.h2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h2;

  const AquaText.h3({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h3;

  const AquaText.h4({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h4;

  const AquaText.h5({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h5;

  const AquaText.subtitle({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.subtitle;

  const AquaText.body1({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body1;

  const AquaText.body2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body2;

  const AquaText.caption1({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption1;

  const AquaText.caption2({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption2;

  const AquaText.h1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h1Medium;

  const AquaText.h2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h2Medium;

  const AquaText.h3Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h3Medium;

  const AquaText.h4Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h4Medium;

  const AquaText.h5Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h5Medium;

  const AquaText.subtitleMedium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.subtitleMedium;

  const AquaText.body1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body1Medium;

  const AquaText.body2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body2Medium;

  const AquaText.caption1Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption1Medium;

  const AquaText.caption2Medium({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption2Medium;

  const AquaText.h1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h1SemiBold;

  const AquaText.h2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h2SemiBold;

  const AquaText.h3SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h3SemiBold;

  const AquaText.h4SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h4SemiBold;

  const AquaText.h5SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.h5SemiBold;

  const AquaText.subtitleSemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.subtitleSemiBold;

  const AquaText.body1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body1SemiBold;

  const AquaText.body2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.body2SemiBold;

  const AquaText.caption1SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption1SemiBold;

  const AquaText.caption2SemiBold({
    super.key,
    required this.text,
    this.color,
    this.size,
    this.maxLines,
    this.textAlign,
    this.height,
    this.underline = false,
    this.overflow,
    this.softWrap,
    this.useTabularFigures,
    this.textDirection,
  }) : style = AquaTypography.caption2SemiBold;

  final String text;
  final TextStyle style;
  final Color? color;
  final double? size;
  final int? maxLines;
  final double? height;
  final TextAlign? textAlign;
  final bool underline;

  /// NEW: optional control over overflow & softWrap
  final TextOverflow? overflow;
  final bool? softWrap;
  final bool? useTabularFigures;

  /// Text direction - when null and text contains numbers, defaults to LTR
  /// to prevent number reversal in RTL languages like Arabic
  final TextDirection? textDirection;

  bool _containsNumbers(String text) {
    return RegExp(r'\d').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    // Default for numbers is to use tabular figures if not explicitly set
    final hasNumbers = _containsNumbers(text);
    final shouldApplyTabular =
        useTabularFigures == true || (useTabularFigures == null && hasNumbers);
    final fontFeatures =
        shouldApplyTabular ? [FontFeature.tabularFigures()] : null;

    // Auto-apply LTR direction for numeric text to prevent reversal in RTL languages
    final effectiveTextDirection =
        textDirection ?? (hasNumbers ? TextDirection.ltr : null);

    final textWidget = Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: effectiveTextDirection,
      softWrap: softWrap,
      overflow: overflow ?? TextOverflow.ellipsis,
      style: style.copyWith(
        color: color,
        fontSize: size,
        height: height,
        fontFeatures: fontFeatures,
      ),
    );

    if (underline) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: color ?? style.color ?? Colors.black,
              width: 1.0,
            ),
          ),
        ),
        child: textWidget,
      );
    }

    return textWidget;
  }
}
