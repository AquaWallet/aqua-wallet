import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class SettingsContentForSideSheet extends StatelessWidget {
  const SettingsContentForSideSheet({
    super.key,
    required this.aquaColors,
    required this.title,
    required this.children,
    this.showBackButton = true,
    this.addIconNextToClose,
    this.widgetAtBottom,
    this.onBackPress,
    this.onClosePress,
  });

  final AquaColors aquaColors;
  final String title;
  final List<Widget> children;
  final Widget? widgetAtBottom;
  final VoidCallback? onBackPress;
  final VoidCallback? onClosePress;
  final bool showBackButton;
  final Widget? addIconNextToClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 25,
            bottom: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: showBackButton
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          AquaIcon.chevronLeft(
                            color: aquaColors.textPrimary,
                            onTap: onBackPress ?? () => Navigator.pop(context),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              AquaText.subtitleSemiBold(
                text: title,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (addIconNextToClose != null) ...[
                      addIconNextToClose!,
                      const SizedBox(width: 8),
                    ],
                    AquaIcon.close(
                      color: aquaColors.textPrimary,
                      onTap: onClosePress ?? () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        const SizedBox(height: 32),
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          children: children,
        ),
        if (widgetAtBottom != null) ...[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: widgetAtBottom!,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
