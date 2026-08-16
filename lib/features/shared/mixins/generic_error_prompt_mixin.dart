import 'package:aqua/common/common.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/models/swap_exceptions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lwk/lwk.dart';
import 'package:ui_components/ui_components.dart';

// Utility mixin to show a generic error prompt on provider errors in listeners
// Combined with the [ExceptionLocalized] errors, this can cover most of the
// error cases in user firendly manner.
//
// Usage:
//
//```dart
// ref.listen(provider, (_, value) {
//   showGenericErrorPromptOnAsyncError(context, value);
// });
//```

mixin GenericErrorPromptMixin on Widget {
  /// Shows the error prompt for [value] and leaves the current flow once the
  /// user acknowledges or dismisses it, for failures that make the flow
  /// unusable. Pass `enabled: false` where the flow can carry on without
  /// [value]. Only valid from the build method of a hook widget.
  void useFlowBlockingErrorPrompt(
    BuildContext context,
    AsyncValue value, {
    bool enabled = true,
  }) {
    final isBlocked = enabled && value.hasError;

    useEffect(() {
      if (!isBlocked) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showGenericErrorPromptOnAsyncError(
          context,
          value,
          buttonLabel: context.loc.close,
          onPrimaryButtonTap: () {
            if (context.mounted) context.pop();
          },
          onDismiss: () {
            if (context.mounted) context.pop();
          },
        );
      });
      return null;
    }, [isBlocked]);
  }

  void showGenericErrorPromptOnAsyncError(
    BuildContext context,
    AsyncValue value, {
    String? title,
    String? buttonLabel,
    VoidCallback? onPrimaryButtonTap,
    VoidCallback? onDismiss,
  }) {
    if (value.hasError) {
      final error = value.error;
      if (context.mounted) {
        final copyableContent = switch (error) {
          SwapServiceQuoteException e => e.message,
          SwapServiceOrderCreationException e => e.message,
          ExceptionLocalized _ => null,
          BoltzError e => e.message,
          LwkError e => e.msg,
          _ => error.toString(),
        };
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AquaModalSheet.show(
            context,
            icon: AquaIcon.warning(color: Colors.white),
            iconVariant: AquaRingedIconVariant.warning,
            title: title ??
                switch (error) {
                  BoltzException e => e.toLocalizedTitle(context),
                  _ => context.loc.somethingWentWrong,
                },
            message: switch (error) {
              ExceptionLocalized e => e.toLocalizedString(context),
              BoltzError e => e.message,
              _ => '',
            },
            copyableContentTitle:
                copyableContent != null ? context.loc.details : null,
            copyableContentMessage: copyableContent,
            primaryButtonText: buttonLabel ?? context.loc.tryAgain,
            onPrimaryButtonTap: () {
              context.pop();
              onPrimaryButtonTap?.call();
            },
            secondaryButtonText: context.loc.commonContactSupport,
            onSecondaryButtonTap: () =>
                context.push(HelpSupportScreen.routeName),
            colors: context.aquaColors,
            copiedToClipboardText: context.loc.copiedToClipboard,
            onDismiss: onDismiss,
          );
        });
      }
    }
  }
}
