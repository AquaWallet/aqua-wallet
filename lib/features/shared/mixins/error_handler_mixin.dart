import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/services/jan3_api_service.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/settings/help_support/pages/help_support_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/components/icon/icon.dart';
import 'package:ui_components/components/modal_sheet/modal_sheet.dart';

mixin ErrorHandlerMixin on Widget {
  void handleRegionRestrictionErrorOnAsyncValue(
    BuildContext context,
    AsyncValue value,
    bool isDarkMode,
  ) {
    if (value.hasError &&
        value.error is RegionRestrictionException &&
        context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final alertModel = CustomAlertDialogUiModel(
          title: context.loc.featureUnavailableInYourRegion,
          subtitle: context.loc.commonRegionBan,
          buttonTitle: context.loc.ok,
          onButtonPressed: () {
            DialogManager().dismissDialog(context);
            context.popUntilPath(AuthWrapper.routeName);
          },
          secondaryButtonTitle: context.loc.commonContactSupport,
          onSecondaryButtonPressed: () {
            DialogManager().dismissDialog(context);
            context.push(HelpSupportScreen.routeName);
          },
          iconVariant: AquaModalSheetVariant.warning,
          icon: AquaIcon.warning(
            color: Colors.white,
          ),
        );

        DialogManager().showDialog(context, alertModel, isDarkMode: isDarkMode);
      });
    }
  }

  void showGenericErrorDialog(BuildContext context, bool isDarkMode) {
    if (context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final alertModel = CustomAlertDialogUiModel(
          title: context.loc.somethingWentWrong,
          subtitle: context.loc.commonPleaseCheckYourConnectionAndTry,
          buttonTitle: context.loc.ok,
          onButtonPressed: () {
            DialogManager().dismissDialog(context);
            context.popUntilPath(AuthWrapper.routeName);
          },
          secondaryButtonTitle: context.loc.commonContactSupport,
          onSecondaryButtonPressed: () {
            DialogManager().dismissDialog(context);
            context.push(HelpSupportScreen.routeName);
          },
          iconVariant: AquaModalSheetVariant.warning,
          icon: AquaIcon.warning(
            color: Colors.white,
          ),
        );

        DialogManager().showDialog(context, alertModel, isDarkMode: isDarkMode);
      });
    }
  }
}
