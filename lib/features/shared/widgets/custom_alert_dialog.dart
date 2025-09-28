import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/common/widgets/custom_dialog.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controlWidgets,
    this.height,
    this.onPopInvoked,
    this.content,
  });

  final String title;
  final String subtitle;
  final List<Widget> controlWidgets;
  final double? height;
  final PopInvokedCallback? onPopInvoked;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: onPopInvoked,
      child: Center(
        child: SingleChildScrollView(
          child: CustomDialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 21.0,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 26.0),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14.0,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                    ),
                  ),
                  if (content != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: content,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: controlWidgets,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  factory CustomAlertDialog.unableToOpenLink({
    required BuildContext context,
  }) {
    return CustomAlertDialog(
      title: context.loc.linkErrorAlertTitle,
      subtitle: context.loc.linkErrorAlertSubtitle,
      height: 240.0,
      controlWidgets: [
        Expanded(
          child: ElevatedButton(
            child: Text(context.loc.ok),
            onPressed: () async {
              context.pop();
            },
          ),
        ),
      ],
    );
  }
}

Future<T?> showCustomAlertDialog<T>({
  required BuildContext context,
  required CustomAlertDialogUiModel uiModel,
  bool isDarkMode = true,
}) {
  AquaModalSheet.show(
    context,
    title: uiModel.title,
    message: uiModel.subtitle,
    primaryButtonText: uiModel.buttonTitle,
    onPrimaryButtonTap: () {
      Navigator.of(context).pop();
      uiModel.onButtonPressed();
    },
    secondaryButtonText: uiModel.secondaryButtonTitle,
    onSecondaryButtonTap: uiModel.onSecondaryButtonPressed != null
        ? () {
            Navigator.of(context).pop();
            uiModel.onSecondaryButtonPressed!();
          }
        : null,
    iconVariant: uiModel.iconVariant ?? AquaModalSheetVariant.normal,
    icon: uiModel.icon,
    colors: isDarkMode ? AquaColors.darkColors : AquaColors.lightColors,
  );

  // Return a completed future since modal sheet doesn't return values
  return Future.value(null);
}
