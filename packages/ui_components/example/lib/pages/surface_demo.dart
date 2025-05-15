import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

class SurfaceItem {
  SurfaceItem({
    required this.label,
    required this.color,
    required this.textColor,
    this.glass = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final bool glass;
}

class SurfaceDemoPage extends HookConsumerWidget {
  const SurfaceDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(prefsProvider).selectedTheme;
    final textColors = useMemoized(
      () => [
        SurfaceItem(
          label: 'Primary',
          color: selectedTheme.colors.textPrimary,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'Secondary',
          color: selectedTheme.colors.textSecondary,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'Tertiary',
          color: selectedTheme.colors.textTertiary,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'Inverse',
          color: selectedTheme.colors.textInverse,
          textColor: selectedTheme.colors.textPrimary,
        ),
      ],
      [selectedTheme],
    );

    final surfaceColors = useMemoized(
      () => [
        SurfaceItem(
          label: 'Primary',
          color: selectedTheme.colors.surfacePrimary,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'BorderPrimary',
          color: selectedTheme.colors.surfaceBorderPrimary,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Secondary',
          color: selectedTheme.colors.surfaceSecondary,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'BorderSecondary',
          color: selectedTheme.colors.surfaceBorderSecondary,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Tertiary',
          color: selectedTheme.colors.surfaceTertiary,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Inverse',
          color: selectedTheme.colors.surfaceInverse,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'Background',
          color: selectedTheme.colors.surfaceBackground,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Selected',
          color: selectedTheme.colors.surfaceSelected,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'BorderSelected',
          color: selectedTheme.colors.surfaceBorderSelected,
          textColor: selectedTheme.colors.textPrimary,
        )
      ],
      [selectedTheme],
    );

    final glassColors = useMemoized(() => [
          SurfaceItem(
            label: 'Surface',
            color: selectedTheme.colors.glassSurface,
            textColor: selectedTheme.colors.textPrimary,
          ),
          SurfaceItem(
            label: 'Inverse',
            color: selectedTheme.colors.glassInverse,
            textColor: selectedTheme.colors.textInverse,
          ),
          SurfaceItem(
            label: 'Background',
            color: selectedTheme.colors.glassBackground,
            textColor: selectedTheme.colors.textPrimary,
          ),
        ]);

    final accentColors = useMemoized(
      () => [
        SurfaceItem(
          label: 'Brand',
          color: selectedTheme.colors.accentBrand,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'BrandTransparent',
          color: selectedTheme.colors.accentBrandTransparent,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Success',
          color: selectedTheme.colors.accentSuccess,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'SuccessTransparent',
          color: selectedTheme.colors.accentSuccessTransparent,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Warning',
          color: selectedTheme.colors.accentWarning,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'WarningTransparent',
          color: selectedTheme.colors.accentWarningTransparent,
          textColor: selectedTheme.colors.textPrimary,
        ),
        SurfaceItem(
          label: 'Danger',
          color: selectedTheme.colors.accentDanger,
          textColor: selectedTheme.colors.textInverse,
        ),
        SurfaceItem(
          label: 'DangerTransparent',
          color: selectedTheme.colors.accentDangerTransparent,
          textColor: selectedTheme.colors.textPrimary,
        ),
      ],
      [selectedTheme],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Text'),
        const SizedBox(height: 16),
        _SectionList(
          title: 'Text',
          items: textColors,
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Surface'),
        const SizedBox(height: 16),
        _SectionList(
          title: 'Surface',
          items: surfaceColors,
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Glass'),
        const SizedBox(height: 16),
        _SectionList(
          title: 'Glass',
          items: glassColors,
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Accent'),
        const SizedBox(height: 16),
        _SectionList(
          title: 'Accent',
          items: accentColors,
        ),
      ],
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.items,
  });

  final String title;
  final List<SurfaceItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) => _SurfaceItem(
          title: title,
          item: items[index],
        ),
      ),
    );
  }
}

class _SurfaceItem extends StatelessWidget {
  const _SurfaceItem({
    required this.title,
    required this.item,
  });

  final String title;
  final SurfaceItem item;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AquaText.caption1(
            text: title,
            color: item.textColor,
          ),
          AquaText.caption1SemiBold(
            text: item.label,
            color: item.textColor,
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: item.glass
          ? AquaCard.glass(
              width: 200,
              height: 200,
              color: item.color,
              onTap: () {},
              child: container,
            )
          : AquaCard(
              width: 200,
              height: 200,
              color: item.color,
              onTap: () {},
              child: container,
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
