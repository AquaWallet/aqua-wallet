import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaBottomSheet extends StatelessWidget {
  const AquaBottomSheet({
    super.key,
    required this.colors,
    required this.content,
    this.topBorderRadius = 24,
  });

  final AquaColors colors;
  final Widget content;
  final double topBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topBorderRadius),
          topRight: Radius.circular(topBorderRadius),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        physics: const BouncingScrollPhysics(),
        child: content,
      ),
    );
  }

  static Future<dynamic> show(
    BuildContext context, {
    required Widget content,
    required AquaColors colors,
    double topBorderRadius = 24,
  }) {
    return showModalBottomSheet(
      context: context,
      constraints: context.isDesktop || context.isTablet
          ? const BoxConstraints(maxWidth: 343)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topBorderRadius),
          topRight: Radius.circular(topBorderRadius),
        ),
      ),
      enableDrag: true,
      // isDismissible: false,
      // anchorPoint: const Offset(0, -100),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AquaBottomSheet(
          colors: colors,
          content: content,
          topBorderRadius: topBorderRadius,
        ),
      ),
    );
  }
}
