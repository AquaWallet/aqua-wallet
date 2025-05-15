import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

class UtilityItemDemoPage extends HookConsumerWidget {
  const UtilityItemDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    final icon = useMemoized(() {
      return AquaIcon.scan(
        color: theme.colors.textPrimary,
      );
    }, [theme]);
    final iconSmall = useMemoized(() {
      return AquaIcon.scan(
        size: 18,
        color: theme.colors.textPrimary,
      );
    }, [theme]);

    return Column(
      children: [
        _RadioDemo(
          icon: icon,
          iconSmall: iconSmall,
        ),
        const SizedBox(height: 40),
        _CheckBoxDemo(
          icon: icon,
          iconSmall: iconSmall,
        ),
        const SizedBox(height: 40),
        _ToggleDemo(
          icon: icon,
          iconSmall: iconSmall,
        ),
      ],
    );
  }
}

class _RadioDemo extends StatelessWidget {
  const _RadioDemo({
    required this.icon,
    required this.iconSmall,
  });

  final Widget icon;
  final Widget iconSmall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const AquaText.h3SemiBold(text: 'Radio'),
        ),
        const _RadioControlStates(),
        const SizedBox(height: 40),
        SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaRadio<bool>.small(
                  value: true,
                  groupValue: false,
                ),
              ),
              const SizedBox(width: 20),
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaRadio<bool>.small(
                  value: true,
                  groupValue: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckBoxDemo extends StatelessWidget {
  const _CheckBoxDemo({
    required this.icon,
    required this.iconSmall,
  });

  final Widget icon;
  final Widget iconSmall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const AquaText.h3SemiBold(text: 'Checkbox'),
        ),
        const _CheckboxControlStates(),
        const SizedBox(height: 40),
        SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaCheckBox.small(
                  value: false,
                ),
              ),
              const SizedBox(width: 20),
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaCheckBox.small(
                  value: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleDemo extends StatelessWidget {
  const _ToggleDemo({
    required this.icon,
    required this.iconSmall,
  });

  final Widget icon;
  final Widget iconSmall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const AquaText.h3SemiBold(text: 'Toggle'),
        ),
        const _ToggleControlStates(),
        const SizedBox(height: 40),
        SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(20),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaToggle(
                  value: false,
                ),
              ),
              const SizedBox(width: 20),
              _ControlSamples(
                icon: icon,
                iconSmall: iconSmall,
                control: const AquaToggle(
                  value: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadioControlStates extends HookWidget {
  const _RadioControlStates();

  @override
  Widget build(BuildContext context) {
    final selectedIndexLarge = useState(1);
    final selectedIndexSmall = useState(1);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            children: [
              AquaRadio<int>(
                value: 0,
                groupValue: selectedIndexLarge.value,
                onChanged: (value) => selectedIndexLarge.value = value,
              ),
              const SizedBox(height: 20),
              AquaRadio<int>.small(
                value: 0,
                groupValue: selectedIndexSmall.value,
                onChanged: (value) => selectedIndexSmall.value = value,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              AquaRadio<int>(
                value: 1,
                groupValue: selectedIndexLarge.value,
                onChanged: (value) => selectedIndexLarge.value = value,
              ),
              const SizedBox(height: 20),
              AquaRadio<int>.small(
                value: 1,
                groupValue: selectedIndexSmall.value,
                onChanged: (value) => selectedIndexSmall.value = value,
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Column(
            children: [
              AquaRadio<int>(
                value: 0,
                groupValue: 1,
                enabled: false,
              ),
              SizedBox(height: 20),
              AquaRadio<int>.small(
                value: 0,
                groupValue: 1,
                enabled: false,
              ),
            ],
          ),
          const SizedBox(width: 20),
          const Column(
            children: [
              AquaRadio<int>(
                value: 1,
                groupValue: 1,
                enabled: false,
              ),
              SizedBox(height: 20),
              AquaRadio<int>.small(
                value: 1,
                groupValue: 1,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckboxControlStates extends HookWidget {
  const _CheckboxControlStates();

  @override
  Widget build(BuildContext context) {
    final valueLarge = useState(false);
    final valueSmall = useState(false);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            children: [
              AquaCheckBox(
                value: valueLarge.value,
                onChanged: (value) => valueLarge.value = !value,
              ),
              const SizedBox(height: 20),
              AquaCheckBox.small(
                value: valueSmall.value,
                onChanged: (value) => valueSmall.value = !value,
              ),
            ],
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              AquaCheckBox(
                value: !valueLarge.value,
                onChanged: (value) => valueLarge.value = value,
              ),
              const SizedBox(height: 20),
              AquaCheckBox.small(
                value: !valueSmall.value,
                onChanged: (value) => valueSmall.value = value,
              ),
            ],
          ),
          const SizedBox(width: 24),
          const Column(
            children: [
              AquaCheckBox(
                value: false,
                enabled: false,
              ),
              SizedBox(height: 20),
              AquaCheckBox.small(
                value: false,
                enabled: false,
              ),
            ],
          ),
          const SizedBox(width: 24),
          const Column(
            children: [
              AquaCheckBox(
                value: true,
                enabled: false,
              ),
              SizedBox(height: 20),
              AquaCheckBox.small(
                value: true,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleControlStates extends HookWidget {
  const _ToggleControlStates();

  @override
  Widget build(BuildContext context) {
    final valueOne = useState(true);
    final valueTwo = useState(false);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Column(
            children: [
              AquaToggle(
                value: valueOne.value,
                onChanged: (value) => valueOne.value = value,
              ),
              const SizedBox(height: 20),
              const AquaToggle(
                value: true,
                enabled: false,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              AquaToggle(
                value: valueTwo.value,
                onChanged: (value) => valueTwo.value = value,
              ),
              const SizedBox(height: 20),
              const AquaToggle(
                value: false,
                enabled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlSamples extends StatelessWidget {
  const _ControlSamples({
    required this.control,
    required this.icon,
    required this.iconSmall,
  });

  final Widget control;
  final Widget icon;
  final Widget iconSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaListItem(
            title: 'Primary',
            iconLeading: icon,
            iconTrailing: control,
            onTap: () {},
          ),
          const SizedBox(height: 20),
          AquaListItem(
            title: 'Primary',
            iconTrailing: control,
            onTap: () {},
          ),
          const SizedBox(height: 19),
          AquaListItem(
            title: 'Primary',
            iconTrailing: iconSmall,
            iconLeading: control,
            onTap: () {},
          ),
          const SizedBox(height: 19),
          AquaListItem(
            title: 'Primary',
            subtitleTrailing: 'Secondary',
            iconLeading: icon,
            iconTrailing: control,
            onTap: () {},
          ),
          const SizedBox(height: 19),
          AquaListItem(
            title: 'Primary',
            subtitleTrailing: 'Secondary',
            iconTrailing: control,
            onTap: () {},
          ),
          const SizedBox(height: 19),
          AquaListItem(
            title: 'Primary',
            subtitleTrailing: 'Secondary',
            iconTrailing: iconSmall,
            iconLeading: control,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
