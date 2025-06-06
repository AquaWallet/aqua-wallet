import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class AquaModalSheet extends StatelessWidget {
  const AquaModalSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.onPrimaryButtonTap,
    this.messageTertiary,
    this.secondaryButtonText,
    this.onSecondaryButtonTap,
    this.copyableContentTitle,
    this.copyableContentMessage,
    required this.icon,
    this.isDanger = false,
    this.colors,
  });

  final String title;
  final String message;
  final String? messageTertiary;
  final String? copyableContentTitle;
  final String? copyableContentMessage;
  final String primaryButtonText;
  final VoidCallback onPrimaryButtonTap;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryButtonTap;
  final Widget icon;
  final bool isDanger;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors?.surfacePrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: colors?.systemBackgroundColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDanger
                      ? colors?.accentDangerTransparent
                      : colors?.surfaceTertiary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDanger
                        ? colors?.accentDanger
                        : colors?.surfaceSecondary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(height: 20),
              AquaText.h4Medium(
                text: title,
                size: 24,
                color: colors?.textPrimary,
              ),
              const SizedBox(height: 6),
              Text(
                message,
                maxLines: 5,
                textAlign: TextAlign.center,
                style: AquaTypography.body1Medium.copyWith(
                  height: 1.2,
                  color: colors?.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (copyableContentTitle != null) ...[
                _CopyableSection(
                  colors: colors,
                  copyableContentTitle: copyableContentTitle,
                  copyableContentMessage: copyableContentMessage,
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                      text: copyableContentMessage!,
                    ));
                    AquaTooltip.show(
                      context,
                      isInfo: true,
                      message: context.loc.copiedToClipboard,
                      foregroundColor: colors?.textInverse,
                      backgroundColor: colors?.glassInverse,
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
              if (messageTertiary != null) ...[
                Text(
                  messageTertiary!,
                  maxLines: 5,
                  textAlign: TextAlign.center,
                  style: AquaTypography.body1SemiBold.copyWith(
                    height: 1,
                    color: colors?.accentDanger,
                  ),
                ),
                const SizedBox(height: 34),
              ],
              AquaButton.primary(
                text: primaryButtonText,
                onPressed: onPrimaryButtonTap,
                isDanger: isDanger,
              ),
              if (secondaryButtonText != null) ...[
                const SizedBox(height: 16),
                AquaButton.secondary(
                  text: secondaryButtonText!,
                  onPressed: onSecondaryButtonTap!,
                )
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? messageTertiary,
    String? copyableContentTitle,
    String? copyableContentMessage,
    required String primaryButtonText,
    required VoidCallback onPrimaryButtonTap,
    String? secondaryButtonText,
    VoidCallback? onSecondaryButtonTap,
    bool isDanger = false,
    required Widget icon,
    AquaColors? colors,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      constraints: const BoxConstraints(
        maxWidth: 343,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      enableDrag: true,
      // isDismissible: false,
      // anchorPoint: const Offset(0, -100),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: AquaModalSheet(
          icon: icon,
          title: title,
          message: message,
          colors: colors,
          primaryButtonText: primaryButtonText,
          onPrimaryButtonTap: onPrimaryButtonTap,
          secondaryButtonText: secondaryButtonText,
          onSecondaryButtonTap: onSecondaryButtonTap,
          copyableContentTitle: copyableContentTitle,
          copyableContentMessage: copyableContentMessage,
          messageTertiary: messageTertiary,
          isDanger: isDanger,
        ),
      ),
    );
  }
}

class _CopyableSection extends HookWidget {
  const _CopyableSection({
    required this.colors,
    required this.copyableContentTitle,
    required this.copyableContentMessage,
    this.onTap,
  });

  final AquaColors? colors;
  final String? copyableContentTitle;
  final String? copyableContentMessage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isExpanded.value) {
            isExpanded.value = true;
          } else {
            onTap?.call();
          }
        },
        borderRadius: BorderRadius.circular(8),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.isHovered) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: const EdgeInsets.only(
            left: 16,
            right: 14,
            top: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: colors?.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors?.surfaceBorderSecondary ??
                  Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => isExpanded.value = !isExpanded.value,
                child: Row(
                  children: [
                    Expanded(
                      child: AquaText.body1SemiBold(
                        text: copyableContentTitle!,
                        color: colors?.textPrimary,
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded.value ? -.5 : 0,
                      child: AquaIcon.chevronDown(
                        size: 16.5,
                        color: colors?.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                height: isExpanded.value ? null : 0,
                padding: const EdgeInsets.only(top: 16),
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: [
                    Expanded(
                      child: AquaText.body2Medium(
                        text: copyableContentMessage!,
                        color: colors?.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    AquaIcon.copy(
                      size: 16.5,
                      color: colors?.textTertiary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
