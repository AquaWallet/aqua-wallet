// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

const kButtonHeightLarge = 56.0;
const kButtonHeightSmall = 34.0;
const kButtonBorderRadius = 8.0;

enum AquaButtonSize {
  small,
  large,
}

enum AquaButtonVariant {
  normal,
  error,
  success,
  warning,
}

enum _ButtonVariant {
  primary,
  secondary,
  tertiary,
  utility,
  utilitySecondary,
}

class AquaButton extends StatelessWidget {
  const AquaButton._({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isInverted = false,
    this.primaryButtonVariant = AquaButtonVariant.normal,
    this.secondaryButtonVariant = AquaButtonVariant.normal,
    required this.variant,
    required this.size,
  });

  factory AquaButton.primary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    AquaButtonVariant variant = AquaButtonVariant.normal,
    bool isLoading = false,
    bool isInverted = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.primary,
      isLoading: isLoading,
      isInverted: isInverted,
      primaryButtonVariant: variant,
      size: size,
    );
  }

  factory AquaButton.secondary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    AquaButtonVariant variant = AquaButtonVariant.normal,
    bool isLoading = false,
    bool isInverted = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.secondary,
      secondaryButtonVariant: variant,
      isLoading: isLoading,
      isInverted: isInverted,
      size: size,
    );
  }

  factory AquaButton.tertiary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    bool isLoading = false,
    bool isInverted = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.tertiary,
      isLoading: isLoading,
      isInverted: isInverted,
      size: size,
    );
  }

  factory AquaButton.utility({
    Key? key,
    required String text,
    Widget? icon,
    bool isLoading = false,
    bool isInverted = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.utility,
      isLoading: isLoading,
      isInverted: isInverted,
      size: AquaButtonSize.small,
    );
  }

  factory AquaButton.utilitySecondary({
    Key? key,
    required String text,
    Widget? icon,
    bool isLoading = false,
    bool isInverted = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.utilitySecondary,
      isLoading: isLoading,
      isInverted: isInverted,
      size: AquaButtonSize.small,
    );
  }

  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final _ButtonVariant variant;
  final AquaButtonSize size;
  final bool isLoading;
  final AquaButtonVariant primaryButtonVariant;
  final AquaButtonVariant secondaryButtonVariant;
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    final buttonChild = switch (this) {
      _ when (isLoading) => Container(
          padding: variant == _ButtonVariant.utility ||
                  variant == _ButtonVariant.utilitySecondary
              ? const EdgeInsets.symmetric(horizontal: 2)
              : EdgeInsetsDirectional.zero,
          constraints: const BoxConstraints(minWidth: 120),
          child: AquaIndefinateProgressIndicator(
            color: switch (variant) {
              _ButtonVariant.primary => Theme.of(context).colorScheme.surface,
              _ButtonVariant.secondary => Theme.of(context).colorScheme.primary,
              _ => Theme.of(context).colorScheme.onSurface,
            },
          ),
        ),
      _ when (icon != null) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (variant == _ButtonVariant.utility ||
                variant == _ButtonVariant.utilitySecondary) ...{
              const SizedBox(width: 4),
            },
            icon!,
            const SizedBox(width: 8),
            Text(text),
          ],
        ),
      _ => Container(
          padding: variant == _ButtonVariant.utility ||
                  variant == _ButtonVariant.utilitySecondary
              ? const EdgeInsets.symmetric(horizontal: 2)
              : EdgeInsetsDirectional.zero,
          child: Text(text),
        )
    };

    final style = switch (variant) {
      _ButtonVariant.primary => size == AquaButtonSize.large
          ? _AquaButtonStyle.primary(
              context,
              variant: primaryButtonVariant,
              isInverted: isInverted,
            )
          : _AquaButtonStyle.primarySmall(
              context,
              variant: primaryButtonVariant,
              isInverted: isInverted,
            ),
      _ButtonVariant.secondary => size == AquaButtonSize.large
          ? _AquaButtonStyle.secondary(
              context,
              variant: secondaryButtonVariant,
            )
          : _AquaButtonStyle.secondarySmall(
              context,
              variant: secondaryButtonVariant,
            ),
      _ButtonVariant.tertiary => size == AquaButtonSize.large
          ? _AquaButtonStyle.tertiary(
              context,
              isInverted: isInverted,
            )
          : _AquaButtonStyle.tertiarySmall(
              context,
              isInverted: isInverted,
            ),
      _ButtonVariant.utility => _AquaButtonStyle.utility(
          context,
          isInverted: isInverted,
        ),
      _ButtonVariant.utilitySecondary => _AquaButtonStyle.utilitySecondary(
          context,
          isInverted: isInverted,
        ),
    };

    return switch (variant) {
      _ButtonVariant.tertiary ||
      _ButtonVariant.utilitySecondary =>
        OutlinedButton(
          onPressed: onPressed,
          style: style.buttonStyle,
          child: buttonChild,
        ),
      _ => ElevatedButton(
          onPressed: onPressed,
          style: style.buttonStyle,
          child: buttonChild,
        ),
    };
  }
}

class _AquaButtonStyle {
  const _AquaButtonStyle({
    required this.buttonStyle,
  });

  final ButtonStyle buttonStyle;

  static const _textStyle = AquaTypography.body1SemiBold;

  static const _textStyleSmall = AquaTypography.body2SemiBold;

  static const _textStyleSmallUtility = AquaTypography.body2SemiBold;

  static const _textSmallPadding = EdgeInsets.symmetric(horizontal: 24);
  static const _textSmallPaddingUtility = EdgeInsets.symmetric(horizontal: 14);

  // Primary

  static _buttonStylePrimary(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
    required bool isInverted,
  }) {
    final foregroundColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = switch (variant) {
      AquaButtonVariant.error => Theme.of(context).colorScheme.error,
      AquaButtonVariant.success => Theme.of(context).colorScheme.primary,
      AquaButtonVariant.warning => Theme.of(context).colorScheme.warning,
      _ => Theme.of(context).colorScheme.primary,
    };
    return ElevatedButton.styleFrom(
      fixedSize: const Size(double.maxFinite, kButtonHeightLarge),
      foregroundBuilder: (context, state, child) => Opacity(
        opacity: state.isDisabled ? 0.5 : 1,
        child: child,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonBorderRadius),
      ),
      textStyle: _textStyle,
    ).copyWith(
      overlayColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.04)),
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: InkSparkle.splashFactory,
      foregroundColor: WidgetStatePropertyAll(
        isInverted ? AquaPrimitiveColors.palatinateBlue750 : foregroundColor,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.isDisabled) {
          return isInverted
              ? foregroundColor
              : backgroundColor.withOpacity(0.5);
        }
        return isInverted ? foregroundColor : backgroundColor;
      }),
      side: WidgetStateProperty.resolveWith((state) {
        if (state.isSelected || state.isFocused) {
          return BorderSide(
            width: 2,
            color: isInverted ? backgroundColor : foregroundColor,
          );
        }
        return null;
      }),
    );
  }

  static primary(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
    required bool isInverted,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStylePrimary(
          context,
          variant: variant,
          isInverted: isInverted,
        ),
      );

  static primarySmall(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
    required bool isInverted,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStylePrimary(
          context,
          variant: variant,
          isInverted: isInverted,
        ).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Secondary

  static _buttonStyleSecondary(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      fixedSize: const Size(double.maxFinite, kButtonHeightLarge),
      foregroundBuilder: (context, state, child) => Opacity(
        opacity: state.isDisabled ? 0.5 : 1,
        child: child,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonBorderRadius),
      ),
      textStyle: _textStyle,
    ).copyWith(
      elevation: const WidgetStatePropertyAll(0),
      splashFactory: InkSparkle.splashFactory,
      overlayColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.04)),
      foregroundColor: WidgetStatePropertyAll(
        switch (variant) {
          AquaButtonVariant.error => Theme.of(context).colorScheme.error,
          AquaButtonVariant.success => Theme.of(context).colorScheme.primary,
          AquaButtonVariant.warning => Theme.of(context).colorScheme.warning,
          _ => Theme.of(context).colorScheme.primary,
        },
      ),
      backgroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.isDisabled) {
          return switch (variant) {
            AquaButtonVariant.error =>
              Theme.of(context).colorScheme.error.withOpacity(0.08),
            AquaButtonVariant.success =>
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
            AquaButtonVariant.warning =>
              Theme.of(context).colorScheme.warning.withOpacity(0.08),
            _ => Theme.of(context).colorScheme.primary.withOpacity(0.08),
          };
        }
        return switch (variant) {
          AquaButtonVariant.error =>
            Theme.of(context).colorScheme.error.withOpacity(0.16),
          AquaButtonVariant.success =>
            Theme.of(context).colorScheme.primary.withOpacity(0.16),
          AquaButtonVariant.warning =>
            Theme.of(context).colorScheme.warning.withOpacity(0.16),
          _ => Theme.of(context).colorScheme.primary.withOpacity(0.16),
        };
      }),
      side: WidgetStateProperty.resolveWith((state) {
        if (state.isSelected || state.isFocused) {
          return BorderSide(
            width: 2,
            color: switch (variant) {
              AquaButtonVariant.error => Theme.of(context).colorScheme.error,
              AquaButtonVariant.success =>
                Theme.of(context).colorScheme.primary,
              AquaButtonVariant.warning =>
                Theme.of(context).colorScheme.warning,
              _ => Theme.of(context).colorScheme.primary,
            },
          );
        }
        return null;
      }),
    );
  }

  static secondary(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStyleSecondary(
          context,
          variant: variant,
        ),
      );

  static secondarySmall(
    BuildContext context, {
    AquaButtonVariant variant = AquaButtonVariant.normal,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStyleSecondary(
          context,
          variant: variant,
        ).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Tertiary

  static _buttonStyleTertiary(
    BuildContext context, {
    required bool isInverted,
  }) {
    return OutlinedButton.styleFrom(
      elevation: 0,
      fixedSize: const Size(double.maxFinite, kButtonHeightLarge),
      foregroundColor: isInverted
          ? AquaPrimitiveColors.palatinateBlue750
          : Theme.of(context).colorScheme.onSurface,
      foregroundBuilder: (context, state, child) => Opacity(
        opacity: state.isDisabled ? 0.5 : 1,
        child: child,
      ),
      side: const BorderSide(color: Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kButtonBorderRadius),
      ),
      textStyle: _textStyle,
    ).copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith((state) {
        if (state.isSelected || state.isFocused) {
          return BorderSide(color: Theme.of(context).colorScheme.primary);
        }
        return BorderSide(
          color: isInverted
              ? AquaPrimitiveColors.palatinateBlue750.withOpacity(
                  state.isDisabled ? 0.5 : 1,
                )
              : Colors.transparent,
        );
      }),
      splashFactory: InkSparkle.splashFactory,
      backgroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.isSelected || state.isFocused) {
          return Theme.of(context).colorScheme.primary;
        }
        if (state.isPressed) {
          return AquaColors.lightColors.surfaceTertiary.withOpacity(0.5);
        }
        return Colors.transparent;
      }),
      foregroundColor: WidgetStatePropertyAll(
        isInverted
            ? AquaPrimitiveColors.palatinateBlue750
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  static tertiary(
    BuildContext context, {
    required bool isInverted,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStyleTertiary(
          context,
          isInverted: isInverted,
        ),
      );

  static tertiarySmall(
    BuildContext context, {
    required bool isInverted,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStyleTertiary(
          context,
          isInverted: isInverted,
        ).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Utility

  static utility(
    BuildContext context, {
    required bool isInverted,
  }) =>
      _AquaButtonStyle(
        buttonStyle: ElevatedButton.styleFrom(
          fixedSize: const Size(double.maxFinite, kButtonHeightSmall),
          foregroundBuilder: (context, state, child) => Opacity(
            opacity: state.isDisabled ? 0.5 : 1,
            child: child,
          ),
          elevation: 8,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonBorderRadius),
          ),
          textStyle: _textStyleSmallUtility,
        ).copyWith(
          splashFactory: InkSparkle.splashFactory,
          foregroundColor: WidgetStatePropertyAll(
            isInverted
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.onSurface,
          ),
          backgroundColor: WidgetStateProperty.resolveWith((state) {
            final color = isInverted
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.surface;
            if (state.isDisabled) {
              return color.withOpacity(0.5);
            }
            return color;
          }),
          padding: const WidgetStatePropertyAll(_textSmallPaddingUtility),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
        ),
      );

  static utilitySecondary(
    BuildContext context, {
    required bool isInverted,
  }) {
    return _AquaButtonStyle(
      buttonStyle: OutlinedButton.styleFrom(
        elevation: 0,
        fixedSize: const Size.fromHeight(kButtonHeightSmall),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundBuilder: (context, state, child) => Opacity(
          opacity: state.isDisabled ? 0.5 : 1,
          child: child,
        ),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonBorderRadius),
        ),
        textStyle: _textStyleSmallUtility,
      ).copyWith(
        side: WidgetStateProperty.resolveWith((state) {
          if (state.isSelected || state.isFocused) {
            return BorderSide(color: Theme.of(context).colorScheme.primary);
          }
          return const BorderSide(color: Colors.transparent);
        }),
        padding: const WidgetStatePropertyAll(_textSmallPaddingUtility),
        splashFactory: InkSparkle.splashFactory,
        backgroundColor: WidgetStateProperty.resolveWith((state) {
          final color = Theme.of(context).colorScheme.surfaceContainerHigh;
          if (state.isDisabled) {
            return color.withOpacity(0.5);
          }
          return Theme.of(context).colorScheme.surfaceContainerHigh;
        }),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
