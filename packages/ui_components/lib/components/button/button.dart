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
    this.isDanger = false,
    required this.variant,
    required this.size,
  });

  factory AquaButton.primary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    bool isLoading = false,
    bool isDanger = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.primary,
      isLoading: isLoading,
      isDanger: isDanger,
      size: size,
    );
  }

  factory AquaButton.secondary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.secondary,
      isLoading: isLoading,
      size: size,
    );
  }

  factory AquaButton.tertiary({
    Key? key,
    required String text,
    Widget? icon,
    AquaButtonSize size = AquaButtonSize.large,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.tertiary,
      isLoading: isLoading,
      size: size,
    );
  }

  factory AquaButton.utility({
    Key? key,
    required String text,
    Widget? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.utility,
      isLoading: isLoading,
      size: AquaButtonSize.small,
    );
  }

  factory AquaButton.utilitySecondary({
    Key? key,
    required String text,
    Widget? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return AquaButton._(
      key: key,
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: _ButtonVariant.utilitySecondary,
      isLoading: isLoading,
      size: AquaButtonSize.small,
    );
  }

  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final _ButtonVariant variant;
  final AquaButtonSize size;
  final bool isLoading;
  final bool isDanger;

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
              _ButtonVariant.primary => AquaColors.lightColors.textInverse,
              _ButtonVariant.secondary => AquaColors.lightColors.textPrimary,
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
          ? _AquaButtonStyle.primary(context, isDanger: isDanger)
          : _AquaButtonStyle.primarySmall(context, isDanger: isDanger),
      _ButtonVariant.secondary => size == AquaButtonSize.large
          ? _AquaButtonStyle.secondary(context)
          : _AquaButtonStyle.secondarySmall(context),
      _ButtonVariant.tertiary => size == AquaButtonSize.large
          ? _AquaButtonStyle.tertiary(context)
          : _AquaButtonStyle.tertiarySmall(context),
      _ButtonVariant.utility => _AquaButtonStyle.utility(context),
      _ButtonVariant.utilitySecondary =>
        _AquaButtonStyle.utilitySecondary(context),
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
    bool isDanger = false,
  }) =>
      ElevatedButton.styleFrom(
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
          AquaColors.lightColors.textInverse,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((state) {
          if (state.isDisabled) {
            return isDanger
                ? AquaColors.lightColors.accentDanger.withOpacity(0.5)
                : AquaColors.lightColors.accentBrand.withOpacity(0.5);
          }
          return isDanger
              ? AquaColors.lightColors.accentDanger
              : AquaColors.lightColors.accentBrand;
        }),
        side: WidgetStateProperty.resolveWith((state) {
          if (state.isSelected || state.isFocused) {
            return BorderSide(
              width: 2,
              color: AquaColors.lightColors.textInverse,
            );
          }
          return null;
        }),
      );

  static primary(
    BuildContext context, {
    bool isDanger = false,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStylePrimary(context, isDanger: isDanger),
      );

  static primarySmall(
    BuildContext context, {
    bool isDanger = false,
  }) =>
      _AquaButtonStyle(
        buttonStyle: _buttonStylePrimary(context, isDanger: isDanger).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Secondary

  static _buttonStyleSecondary(BuildContext context) =>
      ElevatedButton.styleFrom(
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
          AquaColors.lightColors.textPrimary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith((state) {
          if (state.isDisabled) {
            return AquaColors.lightColors.surfaceTertiary.withOpacity(0.5);
          }
          return AquaColors.lightColors.surfaceTertiary;
        }),
        side: WidgetStateProperty.resolveWith((state) {
          if (state.isSelected || state.isFocused) {
            return BorderSide(
              width: 2,
              color: AquaColors.lightColors.accentBrand,
            );
          }
          return null;
        }),
      );

  static secondary(BuildContext context) => _AquaButtonStyle(
        buttonStyle: _buttonStyleSecondary(context),
      );

  static secondarySmall(BuildContext context) => _AquaButtonStyle(
        buttonStyle: _buttonStyleSecondary(context).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Tertiary

  static _buttonStyleTertiary(BuildContext context) => OutlinedButton.styleFrom(
        elevation: 0,
        fixedSize: const Size(double.maxFinite, kButtonHeightLarge),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            return BorderSide(color: AquaColors.lightColors.accentBrand);
          }
          return const BorderSide(color: Colors.transparent);
        }),
        splashFactory: InkSparkle.splashFactory,
        backgroundColor: WidgetStateProperty.resolveWith((state) {
          if (state.isSelected || state.isFocused) {
            return AquaColors.lightColors.accentBrand;
          }
          if (state.isPressed) {
            return AquaColors.lightColors.surfaceTertiary.withOpacity(0.5);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onSurface,
        ),
      );

  static tertiary(BuildContext context) => _AquaButtonStyle(
        buttonStyle: _buttonStyleTertiary(context),
      );

  static tertiarySmall(BuildContext context) => _AquaButtonStyle(
        buttonStyle: _buttonStyleTertiary(context).copyWith(
          padding: const WidgetStatePropertyAll(_textSmallPadding),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
          textStyle: const WidgetStatePropertyAll(_textStyleSmall),
        ),
      );

  // Utility

  static utility(BuildContext context) => _AquaButtonStyle(
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
            Theme.of(context).colorScheme.onSurface,
          ),
          backgroundColor: WidgetStateProperty.resolveWith((state) {
            if (state.isDisabled) {
              return Theme.of(context).colorScheme.surface.withOpacity(0.5);
            }
            return Theme.of(context).colorScheme.surface;
          }),
          padding: const WidgetStatePropertyAll(_textSmallPaddingUtility),
          fixedSize: const WidgetStatePropertyAll(
            Size.fromHeight(kButtonHeightSmall),
          ),
        ),
      );

  static utilitySecondary(BuildContext context) => _AquaButtonStyle(
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
              return BorderSide(color: AquaColors.lightColors.accentBrand);
            }
            return const BorderSide(color: Colors.transparent);
          }),
          padding: const WidgetStatePropertyAll(_textSmallPaddingUtility),
          splashFactory: InkSparkle.splashFactory,
          backgroundColor: WidgetStateProperty.resolveWith((state) {
            if (state.isDisabled) {
              return Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh
                  .withOpacity(0.5);
            }
            return Theme.of(context).colorScheme.surfaceContainerHigh;
          }),
          foregroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
}
