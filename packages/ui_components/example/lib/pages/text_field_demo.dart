import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

import '../providers/providers.dart';
import '../shared/shared.dart';

class TextfieldDemoPage extends HookConsumerWidget {
  const TextfieldDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final controller = useTextEditingController(text: 'Input Text');
    final pasteIcon = useMemoized(() {
      return AquaIcon.paste(
        size: 18,
        color: theme.colors.textPrimary,
      );
    }, [theme]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TextfieldDemoSection(
                controller: controller,
                copyIcon: pasteIcon,
                title: 'Textfield',
              ),
              const SizedBox(width: 20),
              _TextfieldDemoSection(
                controller: controller,
                copyIcon: pasteIcon,
                autofocus: true,
                title: 'Textfield (Focused)',
              ),
              const SizedBox(width: 20),
              _TextfieldDemoSection(
                controller: controller,
                copyIcon: pasteIcon,
                showErrors: true,
                title: 'Textfield (Error)',
              ),
              const SizedBox(width: 20),
              _TextfieldDemoSection(
                controller: controller,
                copyIcon: pasteIcon,
                enabled: false,
                title: 'Textfield (Disabled)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TextAreaDemoSection(
                title: 'Textarea',
                controller: controller,
              ),
              const SizedBox(width: 20),
              _TextAreaDemoSection(
                title: 'Textarea (Focused)',
                controller: controller,
                autofocus: true,
              ),
              const SizedBox(width: 20),
              _TextAreaDemoSection(
                title: 'Textarea (Error)',
                controller: controller,
                showErrors: true,
              ),
              const SizedBox(width: 20),
              _TextAreaDemoSection(
                title: 'Textarea (Disabled)',
                controller: controller,
                enabled: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _SearchFieldDemoSection(
            title: 'Search Field',
            controller: controller,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _TextfieldDemoSection extends HookConsumerWidget {
  const _TextfieldDemoSection({
    required this.controller,
    required this.copyIcon,
    this.autofocus = false,
    this.showErrors = false,
    this.enabled = true,
    required this.title,
  });

  final TextEditingController controller;
  final Widget copyIcon;
  final bool autofocus;
  final bool showErrors;
  final bool enabled;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a shared focus state for all textfields
    final isFocused = useState(autofocus);
    final theme = ref.watch(prefsProvider).selectedTheme;

    final onCopyTap = useCallback(() {
      AquaTooltip.show(
        context,
        message: 'Copied to clipboard',
        foregroundColor: theme.colors.textInverse,
      );
    }, [theme]);

    // Set initial focus state based on autofocus flag
    useEffect(() {
      if (autofocus) {
        isFocused.value = true;
      }
      return null;
    }, []);

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaText.h4SemiBold(text: title),
          const SizedBox(height: 24),
          AquaTextField(
            label: 'Label',
            controller: controller,
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AquaTextField(
            label: 'Label',
            controller: controller,
            trailingIcon: copyIcon,
            onTrailingTap: onCopyTap,
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AquaTextField(
            label: 'Label',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AquaTextField(
            label: 'Label',
            trailingIcon: copyIcon,
            onTrailingTap: onCopyTap,
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          AquaTextField(
            label: 'Label',
            controller: controller,
            assistiveText: 'Assistive Text',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 13),
          AquaTextField(
            label: 'Label',
            controller: controller,
            trailingIcon: copyIcon,
            onTrailingTap: onCopyTap,
            assistiveText: 'Assistive Text',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 13),
          AquaTextField(
            label: 'Label',
            assistiveText: 'Assistive Text',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AquaTextField(
            label: 'Label',
            trailingIcon: copyIcon,
            onTrailingTap: onCopyTap,
            assistiveText: 'Assistive Text',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _TextAreaDemoSection extends HookConsumerWidget {
  const _TextAreaDemoSection({
    required this.controller,
    this.autofocus = false,
    this.showErrors = false,
    this.enabled = true,
    required this.title,
  }) : lineCount = 3;

  final TextEditingController controller;
  final int lineCount;
  final bool autofocus;
  final bool showErrors;
  final bool enabled;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a shared focus state for all textfields
    final isFocused = useState(autofocus);

    // Set initial focus state based on autofocus flag
    useEffect(() {
      if (autofocus) {
        isFocused.value = true;
      }
      return null;
    }, []);

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 375),
      child: Column(
        children: [
          AquaText.h4SemiBold(text: title),
          const SizedBox(height: 24),
          AquaTextField(
            label: 'Label',
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            minLines: lineCount,
            maxLines: lineCount + 2,
            maxLength: 3000,
            showCounter: true,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 22),
          AquaTextField(
            label: 'Label',
            controller: controller,
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            minLines: lineCount,
            maxLines: lineCount + 2,
            maxLength: 3000,
            showCounter: true,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 22),
          AquaTextField(
            label: 'Label',
            assistiveText: 'Assistive Text',
            controller: controller,
            error: showErrors,
            forceFocus: isFocused.value,
            enabled: enabled,
            minLines: lineCount,
            maxLines: lineCount + 2,
            maxLength: 3000,
            showCounter: true,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }
}

class _SearchFieldDemoSection extends HookConsumerWidget {
  const _SearchFieldDemoSection({
    required this.controller,
    this.autofocus = false,
    required this.title,
  });

  final TextEditingController controller;
  final bool autofocus;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocused = useState(autofocus);

    useEffect(() {
      if (autofocus) {
        isFocused.value = true;
      }
      return null;
    }, []);

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 343),
      child: Column(
        children: [
          AquaText.h4SemiBold(text: title),
          const SizedBox(height: 24),
          AquaSearchField(
            hint: "Search...",
            forceFocus: isFocused.value,
          ),
          const SizedBox(height: 20),
          AquaSearchField(
            controller: controller,
            forceFocus: isFocused.value,
          ),
        ],
      ),
    );
  }
}
