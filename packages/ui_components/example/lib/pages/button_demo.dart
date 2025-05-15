import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/models/models.dart';
import 'package:ui_components_playground/shared/extensions/extensions.dart';

import '../providers/providers.dart';

class ButtonDemoPage extends HookConsumerWidget {
  const ButtonDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Buttons'),
        _ButtonsSection(theme: theme),
        const _SectionHeader(title: 'Slider'),
        const _SliderSection(),
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Utility Button'),
        _UtilityButtonsSection(theme: theme),
      ],
    );
  }
}

class _SliderSection extends HookWidget {
  const _SliderSection();

  @override
  Widget build(BuildContext context) {
    final enabledSliderKey = useState(UniqueKey());
    final disabledSliderKey = useState(UniqueKey());
    final sliderState = useState(AquaSliderState.initial);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 44, vertical: 20),
      child: Column(
        children: [
          AquaSlider(
            key: enabledSliderKey.value,
            text: 'Slide',
            stickToEnd: true,
            sliderState: sliderState.value,
            width: 340,
            onConfirm: () {
              sliderState.value = AquaSliderState.inProgress;
              Future.delayed(const Duration(seconds: 3), () {
                sliderState.value = AquaSliderState.completed;
                Future.delayed(const Duration(seconds: 3), () {
                  enabledSliderKey.value = UniqueKey();
                });
              });
            },
          ),
          const SizedBox(height: 20),
          AquaSlider(
            width: 340,
            key: disabledSliderKey.value,
            text: 'Slide',
            enabled: false,
            onConfirm: () {},
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

class _ButtonsSection extends StatelessWidget {
  const _ButtonsSection({
    required this.theme,
  });

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          _ButtonsPanel(
            title: 'Default',
            theme: theme,
            onPressed: () {},
          ),
          const SizedBox(width: 20),
          _ButtonsPanel(
            title: 'Disabled',
            theme: theme,
          ),
          const SizedBox(width: 20),
          _ButtonsPanel(
            title: 'Loading',
            theme: theme,
            isLoading: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ButtonsPanel extends StatelessWidget {
  const _ButtonsPanel({
    required this.title,
    required this.theme,
    this.onPressed,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final AppTheme theme;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 340,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AquaText.subtitleSemiBold(text: title),
          const SizedBox(height: 40),
          AquaButton.primary(
            onPressed: onPressed,
            text: 'Primary',
            isLoading: isLoading,
          ),
          const SizedBox(height: 12),
          AquaButton.primary(
            onPressed: onPressed,
            text: 'Primary',
            icon: AquaIcon.plus(
              color: AquaColors.lightColors.textInverse,
            ),
            isLoading: isLoading,
          ),
          const SizedBox(height: 11),
          AquaButton.secondary(
            onPressed: onPressed,
            text: 'Secondary',
            isLoading: isLoading,
          ),
          const SizedBox(height: 11),
          AquaButton.secondary(
            onPressed: onPressed,
            text: 'Secondary',
            isLoading: isLoading,
            icon: AquaIcon.plus(
              color: AquaColors.lightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 11),
          AquaButton.tertiary(
            onPressed: onPressed,
            text: 'Tertiary',
            isLoading: isLoading,
          ),
          const SizedBox(height: 11),
          AquaButton.tertiary(
            onPressed: onPressed,
            text: 'Tertiary',
            isLoading: isLoading,
            icon: AquaIcon.plus(
              color: theme.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          AquaButton.primary(
            onPressed: onPressed,
            text: 'Primary',
            size: AquaButtonSize.small,
            isLoading: isLoading,
          ),
          const SizedBox(height: 18),
          AquaButton.primary(
            onPressed: onPressed,
            text: 'Primary',
            isLoading: isLoading,
            size: AquaButtonSize.small,
            icon: AquaIcon.plus(
              size: 18,
              color: AquaColors.lightColors.textInverse,
            ),
          ),
          const SizedBox(height: 14),
          AquaButton.secondary(
            onPressed: onPressed,
            text: 'Secondary',
            size: AquaButtonSize.small,
            isLoading: isLoading,
          ),
          const SizedBox(height: 18),
          AquaButton.secondary(
            onPressed: onPressed,
            text: 'Secondary',
            size: AquaButtonSize.small,
            isLoading: isLoading,
            icon: AquaIcon.plus(
              size: 18,
              color: AquaColors.lightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          AquaButton.tertiary(
            onPressed: onPressed,
            text: 'Tertiary',
            size: AquaButtonSize.small,
            isLoading: isLoading,
          ),
          const SizedBox(height: 18),
          AquaButton.tertiary(
            onPressed: onPressed,
            text: 'Tertiary',
            size: AquaButtonSize.small,
            isLoading: isLoading,
            icon: AquaIcon.plus(
              size: 18,
              color: theme.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityButtonsSection extends StatelessWidget {
  const _UtilityButtonsSection({
    required this.theme,
  });

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _UtilityButtonsPanel(
            title: 'Default',
            theme: theme,
            onPressed: () {},
          ),
          const SizedBox(width: 18),
          _UtilityButtonsPanel(
            title: 'Disabled',
            theme: theme,
          ),
          const SizedBox(width: 18),
          _UtilityButtonsPanel(
            title: 'Loading',
            theme: theme,
            isLoading: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _UtilityButtonsPanel extends StatelessWidget {
  const _UtilityButtonsPanel({
    required this.title,
    required this.theme,
    this.onPressed,
    this.isLoading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final AppTheme theme;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AquaText.subtitleSemiBold(text: title),
          const SizedBox(height: 40),
          AquaButton.utility(
            onPressed: onPressed,
            text: 'Utility',
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
          AquaButton.utility(
            onPressed: onPressed,
            text: 'Utility',
            icon: AquaIcon.swap(
              size: 18,
              color: theme.colors.textPrimary,
            ),
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
          AquaButton.utilitySecondary(
            onPressed: onPressed,
            text: 'Utility',
            isLoading: isLoading,
          ),
          const SizedBox(height: 8),
          AquaButton.utilitySecondary(
            onPressed: onPressed,
            text: 'Utility',
            isLoading: isLoading,
            icon: AquaIcon.swap(
              size: 18,
              color: theme.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
