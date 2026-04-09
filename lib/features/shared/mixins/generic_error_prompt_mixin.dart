import 'package:aqua/common/common.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/models/swap_exceptions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:boltz/boltz.dart';
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
  void showGenericErrorPromptOnAsyncError(
    BuildContext context,
    AsyncValue value, {
    String? title,
    String? buttonLabel,
    VoidCallback? onPrimaryButtonTap,
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
            title: title ?? context.loc.somethingWentWrong,
            message: error is ExceptionLocalized
                ? error.toLocalizedString(context)
                : '',
            copyableContentTitle:
                copyableContent != null ? context.loc.details : null,
            copyableContentMessage: copyableContent,
            primaryButtonText: context.loc.tryAgain,
            onPrimaryButtonTap: () {
              context.pop();
              onPrimaryButtonTap?.call();
            },
            secondaryButtonText: context.loc.commonContactSupport,
            onSecondaryButtonTap: () =>
                context.push(HelpSupportScreen.routeName),
            colors: context.aquaColors,
            copiedToClipboardText: context.loc.copiedToClipboard,
          );
        });
      }
    }
  }
}
