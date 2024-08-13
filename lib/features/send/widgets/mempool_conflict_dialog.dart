import 'package:aqua/common/dialogs/dialog_manager.dart';
import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/features/shared/shared.dart';
import 'dart:async';

import 'package:aqua/utils/extensions/context_ext.dart';

class MempoolConflictDialog {
  static void show(BuildContext context,
      {required VoidCallback onRetry, required VoidCallback onCancel}) {
    final dialogManager = DialogManager();

    const threshold = 60;
    int remainingSeconds = threshold;
    late Timer countdownTimer;
    late StateSetter setStateCallback;

    void startCountdown() {
      countdownTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // only update UI every 5 seconds
        setStateCallback(() {
          if (remainingSeconds > 5) {
            remainingSeconds -= 5;
          } else {
            remainingSeconds = 0;
            timer.cancel();
          }
        });
      });
    }

    final alertModel = CustomAlertDialogUiModel(
      title: context.loc.mempoolConflictBroadcastTxExceptionTitle,
      subtitle: context.loc.mempoolConflictBroadcastTxExceptionMessage,
      buttonTitle: context.loc.cancel,
      onButtonPressed: () {
        countdownTimer.cancel();
        Navigator.of(context).pop();
        onCancel();
      },
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          setStateCallback = setState;
          if (remainingSeconds == threshold) {
            startCountdown();
          }
          return Column(
            children: [
              Text(
                context.loc.mempoolConflictBroadcastTxExceptionTimerMessage(
                    remainingSeconds),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: remainingSeconds == 0
                      ? () {
                          countdownTimer.cancel();
                          Navigator.of(context).pop();
                          onRetry();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: remainingSeconds == 0 ? null : Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    context.loc.tryAgain,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    dialogManager.showDialog(context, alertModel);
  }
}
