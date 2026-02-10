import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class AquaNavDrawer extends HookWidget {
  const AquaNavDrawer({
    super.key,
    required this.sections,
    required this.colors,
    this.onLogoTap,
    this.footer,
  });

  final List<AquaNavDrawerSection> sections;
  final Widget? footer;
  final AquaColors colors;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onLogoTap,
              child: Container(
                margin: const EdgeInsetsDirectional.only(
                  start: 16,
                  top: 32,
                ),
                child: AquaUiAssets.svgs.aquaLogo.svg(
                  height: 24,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Divider(
              height: 64,
              thickness: 1,
              color: colors.surfaceBorderPrimary,
            ),
            ListView.separated(
              shrinkWrap: true,
              itemCount: sections.length,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) => sections[index],
            ),
            Divider(
              height: 48,
              thickness: 1,
              color: colors.surfaceBorderPrimary,
            ),
            if (footer != null) ...[
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class AquaNavDrawerSection extends StatelessWidget {
  const AquaNavDrawerSection({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.colors,
  });

  final String title;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AquaText.body1SemiBold(
            text: title,
            color: colors?.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: itemBuilder,
        ),
      ],
    );
  }
}

class AquaNavDrawerItem extends StatelessWidget {
  const AquaNavDrawerItem({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.colors,
  });

  final String label;
  final AquaIconBuilder icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? colors?.surfaceSecondary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
        borderRadius: BorderRadius.circular(8),
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered || state.isPressed) {
            return null;
          }
          return Colors.transparent;
        }),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              icon(
                size: 24,
                color: isSelected ? colors?.textPrimary : colors?.textTertiary,
              ),
              const SizedBox(width: 16),
              AquaText.body1SemiBold(
                text: label,
                color: isSelected ? colors?.textPrimary : colors?.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AquaNavDrawerFooterButton extends StatelessWidget {
  const AquaNavDrawerFooterButton({
    super.key,
    required this.label,
    required this.icon,
    required this.colors,
    this.onTap,
  });

  final String label;
  final AquaIconBuilder icon;
  final VoidCallback? onTap;
  final AquaColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null
          ? () =>
              WidgetsBinding.instance.addPostFrameCallback((_) => onTap?.call())
          : null,
      splashFactory: InkRipple.splashFactory,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Row(
          children: [
            icon(
              color: colors.textPrimary,
            ),
            const SizedBox(width: 16),
            AquaText.body1SemiBold(
              text: label,
              color: colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
