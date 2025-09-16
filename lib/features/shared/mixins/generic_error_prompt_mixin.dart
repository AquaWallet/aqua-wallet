import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

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
  }) {
    if (value.hasError) {
      final error = value.error;
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final alertModel = CustomAlertDialogUiModel(
            title: title ?? context.loc.somethingWentWrong,
            subtitle: error is ExceptionLocalized
                ? error.toLocalizedString(context)
                : error.toString(),
            buttonTitle: buttonLabel ?? context.loc.ok,
            onButtonPressed: () => DialogManager().dismissDialog(context),
          );
          DialogManager().showDialog(context, alertModel);
        });
      }
    }
  }
}
