import 'package:coin_cz/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:coin_cz/features/shared/shared.dart';

class DialogManager {
  static final DialogManager _instance = DialogManager._internal();
  factory DialogManager() => _instance;
  DialogManager._internal();

  bool _isShowingDialog = false;

  void showDialog(BuildContext context, CustomAlertDialogUiModel uiModel) {
    if (!_isShowingDialog) {
      _isShowingDialog = true;
      showCustomAlertDialog(
        context: context,
        uiModel: uiModel,
      ).then((_) => _isShowingDialog = false);
    }
  }

  void dismissDialog(BuildContext context) {
    _isShowingDialog = false;
    context.pop();
  }
}
