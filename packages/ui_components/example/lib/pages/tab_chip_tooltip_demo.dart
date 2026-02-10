import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/extensions/extensions.dart';

import '../providers/providers.dart';

const kCarretIcon = 'assets/svgs/carret.svg';

class TabChipTooltipDemoPage extends HookConsumerWidget {
  const TabChipTooltipDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Tab'),
          const SizedBox(height: 40),
          AquaTabBar(
            tabs: const ['Tab 1', 'Tab 2', 'Tab 3'],
            onTabChanged: (index) {},
          ),
          const SizedBox(height: 40),
          const _SectionHeader(title: 'Chip'),
          const SizedBox(height: 40),
          _ChipDemoSection(theme: theme),
          const SizedBox(height: 40),
          const _SectionHeader(title: 'Tooltip'),
          const SizedBox(height: 40),
          _TooltipDemoSection(theme: theme),
          const SizedBox(height: 40),
          Expanded(
            child: SizedBox(
              width: double.maxFinite,
              child: AquaText.h4SemiBold(
                text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
                        ' Sed do eiusmod tempor incididunt ut labore et dolore'
                        ' magna aliqua.' *
                    10,
                maxLines: 100,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _TooltipDemoSection extends StatelessWidget {
  const _TooltipDemoSection({
    required this.theme,
  });

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AquaText.h4(text: 'Normal'),
          const SizedBox(height: 8),
          _TooltipDemoRow(
            variant: AquaTooltipVariant.normal,
            theme: theme,
          ),
          const SizedBox(height: 20),
          const AquaText.h4(text: 'Normal + Pointer'),
          const SizedBox(height: 8),
          _TooltipDemoRow(
            variant: AquaTooltipVariant.normal,
            showPointer: true,
            theme: theme,
          ),
          const SizedBox(height: 20),
          const AquaText.h4(text: 'Error'),
          const SizedBox(height: 8),
          _TooltipDemoRow(
            variant: AquaTooltipVariant.error,
            theme: theme,
          ),
          const SizedBox(height: 20),
          const AquaText.h4(text: 'Error + Pointer'),
          const SizedBox(height: 8),
          _TooltipDemoRow(
            variant: AquaTooltipVariant.error,
            showPointer: true,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _TooltipDemoRow extends StatelessWidget {
  const _TooltipDemoRow({
    required this.theme,
    required this.variant,
    this.showPointer = false,
  });

  final AppTheme theme;
  final AquaTooltipVariant variant;
  final bool showPointer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AquaButton.utility(
          text: 'Show Tooltip',
          onPressed: () {
            AquaTooltip.show(
              context,
              message: 'Tooltip Title',
              variant: variant,
              pointerPosition: showPointer
                  ? AquaTooltipPointerPosition.bottom
                  : AquaTooltipPointerPosition.none,
              colors: theme.colors,
              onTrailingIconTap: () {
                // Handle close button tap
              },
            );
          },
        ),
        const SizedBox(width: 16),
        AquaButton.utility(
          text: 'Show Info',
          onPressed: () {
            AquaTooltip.show(
              context,
              message: 'Tooltip Title',
              variant: variant,
              pointerPosition: showPointer
                  ? AquaTooltipPointerPosition.top
                  : AquaTooltipPointerPosition.none,
              colors: theme.colors,
              isInfo: true,
              onTrailingIconTap: () {
                // Handle close button tap
              },
            );
          },
        ),
        const SizedBox(width: 16),
        AquaButton.utility(
          text: 'Show Dismissible',
          onPressed: () {
            AquaTooltip.show(
              context,
              message: 'Tooltip Title',
              isDismissible: true,
              variant: variant,
              pointerPosition: showPointer
                  ? AquaTooltipPointerPosition.bottom
                  : AquaTooltipPointerPosition.none,
              colors: theme.colors,
              onTrailingIconTap: () {
                // Handle close button tap
              },
            );
          },
        ),
        const SizedBox(width: 16),
        AquaButton.utility(
          text: 'Show Dismissible Info',
          onPressed: () {
            AquaTooltip.show(
              context,
              message: 'Tooltip Title',
              variant: variant,
              pointerPosition: showPointer
                  ? AquaTooltipPointerPosition.top
                  : AquaTooltipPointerPosition.none,
              colors: theme.colors,
              isInfo: true,
              isDismissible: true,
              onTrailingIconTap: () {
                // Handle close button tap
              },
            );
          },
        ),
      ],
    );
  }
}

class _ChipDemoSection extends StatelessWidget {
  const _ChipDemoSection({
    required this.theme,
  });

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaChip(
                label: '10.46%',
                onTap: () {},
              ),
              const SizedBox(height: 23),
              AquaChip(
                label: '10.46%',
                icon: SvgPicture.asset(
                  kCarretIcon,
                  width: 16,
                  height: 16,
                ),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              AquaChip(
                label: '10.46%',
                compact: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaChip.success(
                label: '10.46%',
                colors: theme.colors,
                onTap: () {},
              ),
              const SizedBox(height: 23),
              AquaChip.success(
                label: '10.46%',
                colors: theme.colors,
                icon: SvgPicture.asset(
                  kCarretIcon,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.colors.accentSuccess,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              AquaChip.success(
                label: '10.46%',
                colors: theme.colors,
                compact: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaChip.error(
                label: '10.46%',
                colors: theme.colors,
                onTap: () {},
              ),
              const SizedBox(height: 23),
              AquaChip.error(
                label: '10.46%',
                colors: theme.colors,
                icon: SvgPicture.asset(
                  kCarretIcon,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.colors.accentDanger,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              AquaChip.error(
                label: '10.46%',
                colors: theme.colors,
                compact: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AquaChip.accent(
                label: '10.46%',
                colors: theme.colors,
                onTap: () {},
              ),
              const SizedBox(height: 23),
              AquaChip.accent(
                label: '10.46%',
                colors: theme.colors,
                icon: SvgPicture.asset(
                  kCarretIcon,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.colors.accentBrand,
                    BlendMode.srcIn,
                  ),
                ),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              AquaChip.accent(
                label: '10.46%',
                colors: theme.colors,
                compact: true,
                onTap: () {},
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AquaText.h4SemiBold(text: title),
    );
  }
}
