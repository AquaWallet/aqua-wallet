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
        maxWidth: 440,
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
                    3,
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
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      crossAxisAlignment: WrapCrossAlignment.end,
      runAlignment: WrapAlignment.spaceEvenly,
      spacing: 16,
      runSpacing: 16,
      children: [
        AquaButton.utility(
          text: 'Show Tooltip',
          onPressed: () {
            AquaTooltip.show(
              context,
              message: 'Tooltip Title',
              foregroundColor: theme.colors.textInverse,
              backgroundColor: theme.colors.glassInverse,
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
              foregroundColor: theme.colors.textInverse,
              backgroundColor: theme.colors.glassInverse,
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
              foregroundColor: theme.colors.textInverse,
              backgroundColor: theme.colors.glassInverse,
              trailingIconColor: theme.colors.textTertiary,
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
              foregroundColor: theme.colors.textInverse,
              backgroundColor: theme.colors.glassInverse,
              trailingIconColor: theme.colors.textTertiary,
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
