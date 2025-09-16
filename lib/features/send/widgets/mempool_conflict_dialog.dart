import 'package:coin_cz/common/dialogs/dialog_manager.dart';
import 'package:coin_cz/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'dart:async';

import 'package:coin_cz/utils/extensions/context_ext.dart';

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
        context.pop();
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
              const SizedBox(height: 30.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: remainingSeconds == 0
                      ? () {
                          countdownTimer.cancel();
                          context.pop();
                          onRetry();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: remainingSeconds == 0 ? null : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: Text(
                    context.loc.tryAgain,
                    style: const TextStyle(fontSize: 16.0),
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
